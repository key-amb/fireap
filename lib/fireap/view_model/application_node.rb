module Fireap::ViewModel
  ##
  # A view object which has info of a particular Application and a Node.
  class ApplicationNode
    attr :appname, :version, :semaphore, :updated_at, :remote_node

    # @param app  [Fireap::Model::Application]
    # @param node [Fireap::Model::Node]

    def initialize(app, node)
      @app  = app
      @node = node

      @appname = app.name
      @version = app.version ? app.version.value : '-'
      @semaphore   = app.semaphore   ? app.semaphore.value : '-'
      @updated_at  = app.update_info ? app.update_info.updated_at  : '-'
      @remote_node = app.update_info ? app.update_info.remote_node : '-'
    end

    # @note For sorting in view
    def <=>(other)
      ret = other.version <=> self.version
      return ret if ret == 0
      self.name <=> other.name
    end
  end
end
