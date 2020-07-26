module SharedModules
  class SlackPostJob < SharedModules::ApplicationJob
    def perform(id, type)
      message = SlackMessage.new
      case type.to_sym
      when :buyer_application_submitted
        message.buyer_application_submitted(BuyerApplication.find(id))
      when :seller_version_submitted
        message.seller_version_submitted(SellerVersion.find(id))
      when :new_problem_report
        message.new_problem_report(ProblemReport.find(id))
      else
        raise "Unexpected type"
      end
    end
  end
end
