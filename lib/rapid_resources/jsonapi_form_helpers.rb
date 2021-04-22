require 'active_support/concern'

module RapidResources
  module JsonapiFormHelpers
    extend ActiveSupport::Concern

    protected

    def jsonapi_resource_form_data(form_id)
      ResourceFormData.new(id: "frm-#{form_id}")
    end

    def render_jsonapi_form(error: nil, form_id: nil, form_page: nil, form_partial: 'form', resource: nil)
      form_page ||= page
      resource ||= @resource

      old_modal = @modal
      old_display_errors = form_page.display_form_errors
      @modal = true
      form_page.display_form_errors = false
      frm_id = controller_path.split('/').last.singularize.camelize.freeze
      form_data = jsonapi_resource_form_data(frm_id) #(id: 'new-project')
      # form_data.submit_title = @resource.new_record? ? 'Create new project' : 'Save project' # page.t(@resource.persisted? ? :'form_action.update' : :'form_action.create')
      form_data.submit_title = form_page.t(resource.persisted? ? :'form_action.update' : :'form_action.create')
      form_data.html = render_to_string(partial: form_partial,
        formats: [:html],
        locals: {
          page: form_page,
          item: resource,
          jsonapi_form: 1,
        })
      @modal = old_modal
      form_page.display_form_errors = old_display_errors

      if error.present?
        if error.is_a?(Result) && error.error.present?
          error_msg = if error.error.present? && error.error[0] == '^'
            error.error[1..]
          else
            "#{form_page.t('form_errors.title')}: #{error.error}"
          end
          form_data.meta[:error] = { message: error_msg }
          form_data.meta[:error][:details] = error[:details] if error[:details].is_a?(Array)
        else
          form_data.meta[:error] = { message: form_page.t('form_errors.title'), details: resource.error_messages.map(&:second) }
        end
        render jsonapi: form_data, status: 422
      else
        render jsonapi: form_data, expose: { url_helpers: self, current_user: current_user }
      end
    end
  end
end
