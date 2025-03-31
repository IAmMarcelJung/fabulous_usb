import serial
import usb.core
import usb.util
from modules import log
import time

# Define special 4-byte acknowledgment sequence
ACK_SEQUENCE = b"\xfa\xb0\xfa\xbf"


def transmit_bitstream_serial(bitstream, port, baudrate=115200):
    with serial.Serial(port, baudrate, timeout=5) as ser:
        ser.write(bitstream)
        log.logger.success(f"Bitstream transmitted!")


def transmit_bitstream_serial_and_check_response(
    bitstream, port, baudrate=115200, repetitions=1
):
    # For some reason needed to keep the config_usb_cdc ack state machine in
    # idle
    bitstream = bitstream + bytes(b"\x12\x34\x56\x78")
    with serial.Serial(port, baudrate, timeout=1) as ser:
        ser.rts = False
        ser.dtr = False
        ser.reset_output_buffer()

        response = ""
        for _ in range(repetitions):
            ser.reset_input_buffer()
            ser.write(bitstream)
            log.logger.debug(f"Waiting in: {ser.in_waiting}")
            log.logger.debug(f"Waiting out: {ser.out_waiting}")
            log.logger.success(f"Bitstream transmitted!")
            # Wait for a 4-byte response
            # Used to be able to make speed measurements transfers to the device if
            # set to false
            response = ser.read(4)
            # log.logger.debug(f"Waiting: {ser.in_waiting}")
            # log.logger.debug(f"Waiting: {ser.in_waiting}")
        ser.close()

        if response == ACK_SEQUENCE:
            log.logger.success(
                f"Received expected acknowledgment: 0x{response.hex().upper()}"
            )
        elif len(response) == 4:
            log.logger.error(
                f"Received unexpected acknowledgment: 0x{response.hex().upper()}"
            )
            exit(1)
        else:
            log.logger.error("No acknowledgment received or response incomplete.")
            exit(1)


def transmit_bitstream_usb_and_check_response_pyusb(
    bitstream, vendor_id=0x1D50, product_id=0x6130
):
    # Find the device
    device = usb.core.find(idVendor=vendor_id, idProduct=product_id)

    if device is None:
        log.logger.error(
            f"Device with VID:0x{vendor_id:04x} PID:0x{product_id:04x} not found"
        )
        exit(1)

    # Detach kernel driver if active
    for interface in range(6):  # Your device has 6 interfaces
        if device.is_kernel_driver_active(interface):
            try:
                device.detach_kernel_driver(interface)
                log.logger.debug(f"Detached kernel driver from interface {interface}")
            except usb.core.USBError as e:
                log.logger.warning(
                    f"Could not detach kernel driver from interface {interface}: {e}"
                )

    # Set configuration
    try:
        device.set_configuration()
        log.logger.debug("Device configuration set")
    except usb.core.USBError as e:
        log.logger.error(f"Error setting configuration: {e}")
        exit(1)

    # Get interface #1 which has the bulk endpoints we want
    interface = device.get_active_configuration()[(1, 0)]

    # Get the OUT endpoint (0x01)
    ep_out = usb.util.find_descriptor(
        interface,
        custom_match=lambda e: usb.util.endpoint_direction(e.bEndpointAddress)
        == usb.util.ENDPOINT_OUT
        and e.bEndpointAddress == 0x01
        and usb.util.endpoint_type(e.bmAttributes) == usb.util.ENDPOINT_TYPE_BULK,
    )

    # Get the IN endpoint (0x81)
    ep_in = usb.util.find_descriptor(
        interface,
        custom_match=lambda e: usb.util.endpoint_direction(e.bEndpointAddress)
        == usb.util.ENDPOINT_IN
        and e.bEndpointAddress == 0x81
        and usb.util.endpoint_type(e.bmAttributes) == usb.util.ENDPOINT_TYPE_BULK,
    )

    if ep_out is None:
        log.logger.error("Bulk OUT endpoint not found")
        exit(1)

    if ep_in is None:
        log.logger.error("Bulk IN endpoint not found")
        exit(1)

    log.logger.debug(
        f"Found OUT endpoint: 0x{ep_out.bEndpointAddress:02x}, IN endpoint: 0x{ep_in.bEndpointAddress:02x}"
    )

    try:
        # Claim the interface
        usb.util.claim_interface(device, 1)
        log.logger.debug("Interface claimed")

        # Write the bitstream
        bytes_written = ep_out.write(bitstream)
        log.logger.success(f"Bitstream transmitted! ({bytes_written} bytes)")

        # Read the response (4 bytes)
        response = ep_in.read(4, timeout=1000)

        # Convert response to bytes
        response_bytes = bytes(response)

        if response_bytes == ACK_SEQUENCE:
            log.logger.success(
                f"Received expected acknowledgment: 0x{response_bytes.hex().upper()}"
            )
        elif len(response_bytes) == 4:
            log.logger.error(
                f"Received unexpected acknowledgment: 0x{response_bytes.hex().upper()}"
            )
            exit(1)
        else:
            log.logger.error("No acknowledgment received or response incomplete.")
            exit(1)

    except usb.core.USBError as e:
        log.logger.error(f"USB error during transmission: {e}")
        exit(1)
    finally:
        # Release the interface
        try:
            usb.util.release_interface(device, 1)
            log.logger.debug("Interface released")
        except:
            pass

        # Release the device
        usb.util.dispose_resources(device)
        log.logger.debug("USB resources disposed")


if __name__ == "__main__":
    pass
