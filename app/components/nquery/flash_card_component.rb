# frozen_string_literal: true

module Nquery
  class FlashCardComponent < Component
    TYPES = %i[notice alert warning info].freeze
    DEFAULT_DELAY = 5000

    attr_reader :type, :dismissible, :html_class, :auto_dismiss, :toast, :delay

    def initialize(message: nil, messages: nil, type: :notice, dismissible: true, toast: true,
                   delay: DEFAULT_DELAY, auto_dismiss: nil, class: nil)
      @messages = Array(messages).presence || Array(message).compact
      @type = type.to_sym
      @toast = toast
      @delay = delay
      @dismissible = dismissible
      @auto_dismiss = auto_dismiss.nil? ? toast : auto_dismiss
      @html_class = binding.local_variable_get(:class)

      raise ArgumentError, "invalid flash type: #{@type}" unless TYPES.include?(@type)
      raise ArgumentError, "message is required" if @messages.empty?
    end

    def messages
      @messages
    end

    def role
      type == :alert ? "alert" : "status"
    end

    def css_class
      classes = ["nq-flash-card", "nq-flash-card-#{type}"]
      classes << (toast ? "nq-flash-card-toast" : "nq-flash-card-inline")
      classes << html_class if html_class.present?
      classes.join(" ")
    end

    def dismissible?
      dismissible
    end

    def auto_dismiss?
      auto_dismiss
    end

    def toast?
      toast
    end
  end
end
