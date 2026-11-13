module Approvals
  # Asking a client to approve a task, answered in the portal by someone who can approve for them
  # (README.md). It owns its table (approvals_requests), points at core records by id, and reaches
  # the core only through the plugin contract (docs/plugin-contract.md in Runwell). Remove it and
  # Runwell runs as before.
  class Engine < ::Rails::Engine
    # Routes join the app's route set (as approvals_*), so the core layout's helpers work.
    initializer "approvals.routes" do |app|
      app.routes.append do
        scope "approvals", module: "approvals", as: "approvals" do
          resources :requests, only: :index
          resources :tasks, only: [] do
            resource :request, only: %i[create destroy]
          end
        end
        scope "portal", module: "approvals/portal", as: "approvals_portal" do
          resources :approvals, only: :index, controller: "decisions"
          post "tasks/:task_id/approval", to: "decisions#create", as: :decision
        end
      end
    end

    initializer "approvals.models" do
      ActiveSupport.on_load(:runwell_task) { has_many :approvals_requests, class_name: "Approvals::Request", dependent: :delete_all }
    end

    config.to_prepare do
      Runwell::Plugins.register :approvals, name: "Approvals", version: Approvals::VERSION, author: "Martin Business Consultants",
        enabled_by_default: false, requires: ">= 6.0.0", homepage: "https://github.com/Martin-Business-Consultants/runwell-approvals",
        description: "Ask a client to approve something: on any task shared with them, with a line saying what you need a yes on. Their people who can approve are emailed and decide in the portal, approving or asking for changes, and the answer lands on the task's discussion and in its history."
      Runwell::Plugins.slot :task_aside, :approvals, "approvals/slots/task_aside"
      Runwell::Plugins.slot :task_notice, :approvals, "approvals/slots/task_notice"
      Runwell::Plugins.slot :portal_task, :approvals, "approvals/slots/portal_task"
      Runwell::Plugins.slot :portal_dashboard, :approvals, "approvals/slots/portal_dashboard"
      Runwell::Plugins.stylesheet :approvals, "approvals/approvals"
    end
  end
end
