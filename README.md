# Discourse Segment.io Plug-in

Emits user events to segment.io

#### Current support

* User identify
* User Track "Signed Up"
* User Track "Post Created"
* User Track "Post Liked"
* User Track "Topic Created"
* User Track "Topic Tag Created"
* User Page View

# Usage

Once installed, the plugin will automatically push the supported events to Segment.io

# Backfilling

If you'd like to trigger the segments for existing users, open up a rails console and
run the following:

```ruby
User.pluck(:id).each do |uid|
  Jobs.enqueue(:emit_segment_user_identify, user_id: uid)
end
```

# Installation

Watch Tutorial Video: https://youtu.be/AKR3ki9Kj38

In segment.io you will need a `ruby` source to receive the incoming events.

# Contributing

Please see [CONTRIBUTING.md](/CONTRIBUTING.md).

# License

discourse-segment-io-plugin is Copyright © 2016 Kyle Welsby. It is free software, and may be redistributed under the terms specified in the [LICENSE](./license) file.
