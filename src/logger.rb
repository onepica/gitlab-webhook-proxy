require 'configatron'
require 'logging'

module GitlabHook
  module Logger
    def log(data, priority = )
      unless Project::action_allowed? data['object_kind'], data['object_attributes']['action']
        puts "action not allowed: #{data['object_kind']}, #{data['object_attributes']['action']}"
        return false
      end

      receivers = GitlabHook::MergeRequest.new(data).match_receivers

      puts receivers

      result = true

      if receivers[:assignee]
        # response = GitlabHook::Sender.new.send(data, {
        #     channel: receivers[:assignee],
        #     template_name: 'assignee',
        # })
        # result = (response and response.instance_of? Net::HTTPOK) ? result : false

        # debug
        puts receivers[:assignee]
        # puts response.class
      end

      if receivers[:team]
        receivers[:team].each do |receiver|
          # response = GitlabHook::Sender.new.send(data, {
          #     channel: receiver,
          #     template_name: 'group',
          # })
          # result = (response and response.instance_of? Net::HTTPOK) ? result : false

          # debug
          puts receiver
          # puts response.class
        end
      end

      result
    end
  end
end
