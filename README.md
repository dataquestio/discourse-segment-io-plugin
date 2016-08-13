# Discourse Segment.io Plug-in

Emits user events to segment.io

#### Current support

* User identify
* User Track "Signed Up"
* User Track "Post Created"
* User Track "Topic Created"

# Usage

Once installed, the plugin will automatically push the supported events to Segment.io

# Installation

To install using docker, add the following to your `app.yml` in the plugins section:

    env:
      SEGMENT_IO_KEY: xxx
    hooks:
      after_code:
        - exec:
            cd: $home/plugins
            cmd:
              - git clone https://github.com/kylewelsby/discourse-segment-io-plugin.git

and rebuild your docker via

    cd /var/discourse
    ./launcher rebuild app

# Contributing

Please see [CONTRIBUTING.md](/CONTRIBUTING.md).

# License

discourse-segment-io-plugin is Copyright © 2016 Kyle Welsby. It is free software, and may be redistributed under the terms specified in the [LICENSE](./license) file.
