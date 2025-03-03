# Scripts

Contains python scripts used for the project.

`jtag.py`: Used as a wrapper for `ftdi.py` script in the `JTAG-interface`
submodule. 

The following environment variables have to be set in order to use it with an
`FT232HQ` FTDI adapter:

```console
PYTHONPATH=$(realpath ../JTAG-interface):$PYTHONPATH
BLINKA_FT232H=1
```
