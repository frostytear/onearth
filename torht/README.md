# Building and Installing OE2

## Docker setup

The included Dockerfile will build an image with OE2. The build is configured
for CI tests.

To run, simply build the image `docker build -t onearth_2 .`, and then start a
container using that image. Make sure to expose port 80 on the container to
access the image server.

### CI Tests



## Notes

The date-snapping service also determines the filenames mod_mrf will look for
when trying to find data for a specific date. Currently, it formats them as
`{layer}{UNIX_epoch}.(idx|pjg)`.
