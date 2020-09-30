# name: Segment.io
# about: Import your Discourse data to your Segment.io warehouse
# version: 0.0.1
# authors: Kyle Welsby <kyle@mekyle.com>

gem 'commander', '4.5.2' # , require: false # for analytics-ruby
gem 'analytics-ruby', '2.2.2', require: false # 'segment/analytics'

enabled_site_setting :segment_io_enabled

after_initialize do
  require 'segment/analytics'

  class Analytics
    def self.method_missing(method, *args)
      return unless SiteSetting.segment_io_enabled
      analytics = Segment::Analytics.new(
        write_key: SiteSetting.segment_io_write_key
      )
      super(method, *args) unless analytics.respond_to?(method)
      analytics.send(method, *args)
      analytics.flush
    end
  end

  require_dependency 'jobs/base'
  module ::Jobs
    class EmitSegmentUserIdentify < Jobs::Base
      def execute(args)
        return unless SiteSetting.segment_io_enabled?
        user = User.find_by_id(args[:user_id])
        user.emit_segment_user_identify if user
      end
    end
  end

  require_dependency 'user'
  class ::SingleSignOnRecord
    # In order to send the DQ user_id to segment, we need to
    # send the segment events for user creation AFTER the SSO record
    # is created not when the user is created. So, we emit the *identify*
    # and *track sign up* events on SingleSignOnRecord not User.
    after_create :emit_segment_user_identify
    after_create :emit_segment_user_created

    def emit_segment_user_identify
      user = self.user
      Analytics.identify(
        user_id: user.id,
        traits: {
          name: user.name,
          username: user.username,
          email: user.email,
          created_at: user.created_at,
          dq_user_id: external_id
        },
        context: {
          ip: user.ip_address
        }
      )
    end

    def emit_segment_user_created
      user = self.user
      Analytics.track(
        user_id: user.id,
        event: 'Discourse Signed Up',
        properties: {
          user_email: user.email,
          dq_user_id: external_id
        }
      )
    end

  end

  require_dependency 'application_controller'
  class ::ApplicationController
    before_action :emit_segment_user_tracker

    SEGMENT_IO_EXCLUDES = {
      'stylesheets' => :all,
      'user_avatars' => :all,
      'about' => ['live_post_counts'],
      'topics' => ['timings']
    }.freeze

    def emit_segment_user_tracker
      if current_user && !segment_common_controller_actions?
        Analytics.page(
          user_id: current_user.id,
          name: "#{controller_name}##{action_name}",
          properties: {
            url: request.original_url,
            user_email: current_user.email
          },
          context: {
            ip: request.ip,
            userAgent: request.user_agent
          }
        )
      end
    end

    def segment_common_controller_actions?
      SEGMENT_IO_EXCLUDES.keys.include?(controller_name) &&
      (SEGMENT_IO_EXCLUDES[controller_name] == :all ||
       SEGMENT_IO_EXCLUDES[controller_name].include?(action_name) )
    end
  end

  require_dependency 'post'
  class ::Post
    after_create :emit_segment_post_created

    def emit_segment_post_created
      Analytics.track(
        user_id: user_id,
        event: 'Discourse Post Created',
        properties: {
          topic_id: topic_id,
          post_number: post_number,
          created_at: created_at,
          since_topic_created: (created_at - topic.created_at).to_i,
          reply_to_post_number: reply_to_post_number,
          user_email: user.email
        }
      )
    end
  end

  require_dependency 'topic'
  class ::Topic
    after_create :emit_segment_topic_created

    def emit_segment_topic_created
      Analytics.track(
        user_id: user_id,
        event: 'Discourse Topic Created',
        properties: {
          slug: slug,
          title: title,
          url: url,
          user_email: user.email
        }
      )
    end
  end

  require_dependency 'topic_tag'
  class ::TopicTag
    after_create :emit_segment_topic_tagged

    def emit_segment_topic_tagged
      Analytics.track(
        anonymous_id: -1,
        event: 'Discourse Topic Tag Created',
        properties: {
          topic_id: topic_id,
          tag_name: tag.name
        }
      )
    end
  end

  require_dependency 'user_action'
  class ::UserAction
    after_create :emit_segment_post_liked, if: -> { self.action_type == UserAction::LIKE }

    def emit_segment_post_liked
      Analytics.track(
        user_id: user_id,
        event: 'Discourse Post Liked',
        properties: {
          post_id: target_post_id,
          topic_id: target_topic_id,
          like_count: target_topic.like_count,
          user_email: user.email
        }
      )
    end
  end
end
