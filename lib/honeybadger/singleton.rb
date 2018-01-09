require 'forwardable'
require 'honeybadger/agent'

# Honeybadger's public API is made up of two parts: the {Honeybadger} singleton
# module, and the {Agent} class. The singleton module delegates its methods to
# a global agent instance, {Agent#instance}; this allows methods to be accessed
# directly, for example when calling +Honeybadger.notify+:
#
#   begin
#     raise 'testing an error report'
#   rescue => err
#     Honeybadger.notify(err)
#   end
#
# Custom agents may also be created by users who want to report to multiple
# Honeybadger projects in the same app (or have fine-grained control over
# configuration), however most users will use the global agent.
#
# @see Honeybadger::Agent
module Honeybadger
  extend Forwardable
  extend self

  # @!macro [attach] def_delegator
  #   @!method $2(...)
  #     Forwards to {$1}.
  #     @see Agent#$2
  def_delegator :'Honeybadger::Agent.instance', :notify
  def_delegator :'Honeybadger::Agent.instance', :check_in
  def_delegator :'Honeybadger::Agent.instance', :context
  def_delegator :'Honeybadger::Agent.instance', :configure
  def_delegator :'Honeybadger::Agent.instance', :get_context
  def_delegator :'Honeybadger::Agent.instance', :flush
  def_delegator :'Honeybadger::Agent.instance', :stop
  def_delegator :'Honeybadger::Agent.instance', :exception_filter
  def_delegator :'Honeybadger::Agent.instance', :exception_fingerprint
  def_delegator :'Honeybadger::Agent.instance', :backtrace_filter

  # @!macro [attach] def_delegator
  #   @!method $2(...)
  #     @api private
  #     Forwards to {$1}.
  #     @see Agent#$2
  def_delegator :'Honeybadger::Agent.instance', :config
  def_delegator :'Honeybadger::Agent.instance', :init!
  def_delegator :'Honeybadger::Agent.instance', :with_rack_env

  # @api private
  def load_plugins!
    Dir[File.expand_path('../plugins/*.rb', __FILE__)].each do |plugin|
      require plugin
    end
    Plugin.load!(self.config)
  end

  # @api private
  def install_at_exit_callback
    at_exit do
      if $! && !$!.is_a?(SystemExit) && Honeybadger.config[:'exceptions.notify_at_exit']
        Honeybadger.notify($!, component: 'at_exit', sync: true)
      end

      Honeybadger.stop if Honeybadger.config[:'send_data_at_exit']
    end
  end

  # @deprecated
  def start(config = {})
    raise NoMethodError, <<-WARNING
`Honeybadger.start` is no longer necessary and has been removed.

  Use `Honeybadger.configure` to explicitly configure the agent from Ruby moving forward:

  Honeybadger.configure do |config|
    config.api_key = 'project api key'
    config.exceptions.ignore += [CustomError]
  end
WARNING
  end
end
