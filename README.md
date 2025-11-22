# Dockware WEB

[![MIT licensed](https://img.shields.io/github/license/MarcoFaul/dockware-web-frankenphp.svg?style=flat-square)](https://github.com/dockware/dockware/blob/master/LICENSE)
![Docker Pulls](https://img.shields.io/docker/pulls/MarcoFaul/dockware-web-frankenphp)
![Docker Image Size](https://img.shields.io/docker/image-size/MarcoFaul/dockware-web-frankenphp)

Welcome to the dockware Docker images! For more information, visit [dockware.io](https://dockware.io).

## What is Dockware WEB?

Dockware WEB is designed to provide developers with an optimal environment that includes multiple
"latest" PHP and Node.js versions, Xdebug, and essential tools.
Its goal is to streamline development workflows with an up-to-date and clean setup.

Just run the container, and develop and Node, PHP or other web applications
without the hazzle of setting up your local environment.

> For all these cool features like Xdebug, Filebeat, Supervisor and more, please check out the Docs at www.dockware.io

## Quick Start

```bash 
docker run -p 80:80 diwmarco/web-frankenphp:latest
```

That's it, connect into the container and start coding.

If you need a more complex setup, you can use a `docker-compose.yml` file.
This sample even mounts your local **src** folder to the Apache DocRoot and also switches
to PHP 8.4 and Node 22.

```yaml
  website:
    image: diwmarco/web-frankenphp:latest
    volumes:
      - "./src:/var/www/html"
    environment:
      - PHP_VERSION=8.4
      - NODE_VERSION=24
```

## Documentation

For all these cool features like Xdebug, Filebeat, PHP Switching, Supervisor and more,
please check out the Docs at [https://dockware.io](https://dockware.io).

## Releases and Versions

Dockware web has two main types of releases:

1. **Nightly Builds**: Available with the tag `dev-main`.
2. **Stable Versions**: Versioned releases like `2.0.0`, `2.0.1`, etc.

Check the `CHANGELOG.md` file for details on all changes and updates. The changelog is also included within the image.

## Contribution

Contributions are welcome! Please refer to the `CONTRIBUTING.md` file for guidelines
on how to contribute effectively.

## License

Dockware WEB is provided under the MIT license.
As with all Docker images, this project may include software under other licenses.
Users are responsible for ensuring compliance with all relevant licenses for software
contained within the image.