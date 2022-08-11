# skyscraper-docker
Rom scraper docker image, based on the awesome [Skyscraper by Lars Muldjord](https://github.com/muldjord/skyscraper).

Architectures supported by this image are:

- linux/amd64
- linux/arm64

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
- `SKYSCRAPER_MODULES`: set the default scraping modules in a comma-separated list (default: `thegamesdb`)
- `SKYSCRAPER_PLATFORM_MODULES`: set the scraping modules to use for each platform, the value of this variable can be set to edit the default modules for specific platforms and is a columns-separated list of entries, each entry has the platform name followed by a semicolumn and a comma separated list of modules, e.g. `psx:screenscraper,thegamesdb;mame:arcadedb;fba:arcadedb`
- `SKYSCRAPER_ROMS_DIR`: roms base path if it is differente from `/roms`
- `SKYSCRAPER_GAMELIST_DIR`: if set, generate gamelists in this path instead of roms directory (watch out to absolute rom paths if mounting `/roms` volume in the default path). If this is a relative path, it is considered relative to each system roms folder, if it is an absolute path, a folder with the system name will be created inside this path for each processed system
- `SKYSCRAPER_MEDIA_DIR`: if set, generate media files in this path instead of default directory (watch out to absolute rom paths if mounting `/roms` volume in the default path). If this is a relative path, it is considered relative to each system roms folder, if it is an absolute path, a folder with the system name will be created inside this path for each processed system
- `SKYSCRAPER_FLAGS`: additional flags passed to commandline invocations (default: `uinattend,unattendskip,relative`)
- `SKYSCRAPER_NO_RELATIVE_PATHS`: if set to `true`, avoid using `relative` flag by default
- `SKYSCRAPER_ROMS_TO_SUBDIR`: if set to `true`, keep the roms of a system in the `/roms/$system/roms` subdir to limit performance issues when mixing gamelists and roms files in a single tree, this implies `SKYSCRAPER_GAMELIST_DIR=.`
- `SKYSCRAPER_RUN_GLOBAL_UPDATE`: if set to `true`, try to update all systems gamelists, otherwise only systems with new files will be treated
