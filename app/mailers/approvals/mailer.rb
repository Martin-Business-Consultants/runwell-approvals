module Approvals
  # Tells someone who can approve for a client that their answer is needed, in the core's email
  # pieces, with a button to the task in the portal.
  class Mailer < ApplicationMailer
    def asked
      @request, @contact = params[:request], params[:contact]
      @task = @request.task
      return unless @request.pending? && @request.decidable_by?(@contact)

      @url = portal_tasks_url(task: @task.id, status: "all")
      mail to: @contact.email, subject: "Your approval is needed: #{@task.title}"
    end
  end
end
