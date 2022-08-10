# skyscraper-docker
Rom scraper docker image, based on the awesome [Skyscraper by Lars Muldjord](https://github.com/muldjord/skyscraper).

Architectures supported by this image are:

- linux/amd64
- linux/arm64
- linux/armhf

## Quick Start

Pull latest build from docker hub

```
docker pull mellotanica/skyscraper
````

Launch the docker container with the following command:

``` 
docker run -d \
    --name=skyscraper
    -v /path/to/roms:/path/to/roms \
    mellotanica/skyscraper Skyscraper -p nes -s screenscraper -u uesr:hash -i /path/to/roms/nes
```

## Automatic rescan

The container provides an automatic scraping utility, refreshing game folders only when the contents change.
To use this feature simply run the container (with relevant settings) without specifying a Skyscraper command.

The recommended way to use this feature is through docker-compose:
```
version: "3"
services:
  skyscraper:
    image: mellotanica/skyscraper:latest
    container_name: skyscraper
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - SKYSCRAPER_FRONTEND=emulationstation
    volumes:
      - /path/to/roms:/path/to/roms
      - ./configs:/configs
```

## Configurations

### Volumes

The volumes used by the container are:

- `/roms`: root roms folder, containing a directory for each system with the roms inside, if you want to use a different path (e.g. to have correct absolute paths for game files) remember to set `SKYSCRAPER_ROMSDIR` to this path as well.
- `/configs`: configurations folder, the base config.ini will be read from this folder if mounted
- `/cache`: automatic volume created by the container that will hold the scraping cache

### Options

The behavior of the scraper can be configured using both environment variables or standard Skyscraper config.ini file (or both).

For the config.ini options check the [official documentation](https://github.com/muldjord/skyscraper/blob/master/docs/CONFIGINI.md), to enable this file, create your configurations in a local directory and mount it as a volume as shown before.

The environment variables supported by the container are:

- `PUID`: user id used by the container environment to edit files
- `PGID`: group id used by the container environment to edit files
- `SKYSCRAPER_FRONTEND`: set the output format, see Skyscraper `-f` flag
- `SKYSCRAPER_MODULE`: set the scraping module, see Skyscraper `-s` flag
- `SKYSCRAPER_USERCREDS`: set the scraper credentials, see Skyscraper `-u` flag
- `SKYSCRAPER_ROMSDIR`: roms base path if it is differente from `/roms`
