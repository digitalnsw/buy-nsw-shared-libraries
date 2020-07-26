module SharedModules
  class SlackReportingJob < SharedModules::ApplicationJob
    around_perform do |job, block|
      start_time = Time.now

      # this calls perform and retrieves the result
      fields = block.call

      end_time = Time.now
      delta_ms = (end_time - start_time) * 1000

      # Finally, send a job completion message to the slack.
      SlackMessage.new.message(
        text: "#{self.class} completed at #{end_time} after #{'%.4f' % delta_ms}ms",
        attachments: [{
          fields: fields,
        },],
      )
    end
  end
end
