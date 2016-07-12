%w( v1 ).each do |lib|
  require "scooter/httpdispatchers/activity/v1/#{lib}"
end

module Scooter
  module HttpDispatchers
    module Activity
      include Scooter::HttpDispatchers::Activity::V1
      include Scooter::Utilities

      def set_activity_service_path(connection=self.connection)
        set_url_prefix
        connection.url_prefix.path = '/activity-api'
      end

      # Used to compare replica activity to master. Raises exception if it does not match.
      # @param [BeakerHost] host_name
      def activity_database_matches_self?(host_name)
        original_host_name = self.host
        begin
          self.host = host_name.to_s
          initialize_connection
          other_rbac_events       = get_rbac_events.env.body
          other_classifier_events = get_classifier_events.env.body
        ensure
          self.host = original_host_name
          initialize_connection
        end

        self_rbac_events       = get_rbac_events.env.body
        self_classifier_events = get_classifier_events.env.body

        rbac_events_match       = other_rbac_events == self_rbac_events
        classifier_events_match = other_classifier_events == self_classifier_events

        errors = ''
        errors << "Rbac events do not match\r\n" unless rbac_events_match
        errors << "Classifier events do not match\r\n" unless classifier_events_match

        @faraday_logger.warn(errors.chomp) unless errors.empty?
        errors.empty?
      end

    end
  end
end
