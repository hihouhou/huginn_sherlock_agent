module Agents
  class SherlockAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '1h'

    description do
      <<-MD
      The sherlock agent fetches creates an event from csv sherlock's output.

      `debug` is used for verbose mode.

      `filepath` for the parsed CSV file from sherlock's research .

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:
        {
          "username": "XXXXXXXX",
          "name": "2Dimensions",
          "url_main": "https://2Dimensions.com/",
          "url_user": "https://2Dimensions.com/a/XXXXXXXX",
          "exists": "Available",
          "http_status": "404",
          "response_time_s": "1.3680214039050043"
        }
    MD

    def default_options
      {
        'filepath' => '',
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'changes_only' => 'true'
      }
    end

    form_configurable :filepath, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :changes_only, type: :boolean

    def validate_options
      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      unless options['filepath'].present?
        errors.add(:filepath, "filepath is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          fetch
        end
      end
    end

    def check
      fetch
    end

    private

    def fetch
      
      data_json = CSV.open(interpolated['filepath'], :headers => true).map { |x| x.to_h }.to_json
      payload = JSON.parse(data_json)

      if interpolated['debug'] == 'true'
        log payload
      end

      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['last_status']
          if "#{memory['last_status']}" == ''
            payload.each do |social_networks|
                create_event payload: social_networks
            end
          else
            log "not equal"
            last_status = memory['last_status'].gsub("=>", ": ").gsub(": nil", ": null").gsub(", nil", ", null")
            last_status = JSON.parse(last_status)
            payload.each do |social_networks|
              found = false
              if interpolated['debug'] == 'true'
                log "#{found}"
              end
              last_status.each do |social_networksbis|
                if social_networks['name'] == social_networksbis['name'] && social_networks['exists'] == social_networksbis['exists']
                  found = true
                  if interpolated['debug'] == 'true'
                    log "#{found}"
                    log social_networksbis
                  end
                end
              end
              if found == false
              create_event payload: social_networks
              end
            end
          end
          memory['last_status'] = payload.to_s
        end
      else
        create_event payload: payload
        if payload.to_s != memory['last_status']
          memory['last_status'] = payload.to_s
        end
      end
    end
  end
end
