module Thrust
  class Testflight
    def initialize(thrust_executor, out, input, api_token, team_token)
      @thrust_executor = thrust_executor
      @out = out
      @in = input
      @git = Thrust::Git.new(@out, @thrust_executor)
      @api_token = api_token
      @team_token = team_token
    end

    def upload(package_file, notify, distribution_list, autogenerate_deploy_notes, deployment_target, dsym_path = nil)
      if dsym_path
        @out.puts 'Zipping dSYM...'
        zipped_dsym_path = "#{dsym_path}.zip"
        @thrust_executor.system_or_exit "zip -r -T -y '#{zipped_dsym_path}' '#{dsym_path}'"
        @out.puts 'Done!'
      end

      if autogenerate_deploy_notes
        message_file_path = @git.generate_notes_for_deployment(deployment_target)
      else
        message_file_path = Thrust::UserPrompt.get_user_input('Deploy Notes: ', @out, @in)
      end

      @thrust_executor.system_or_exit [
        'curl http://testflightapp.com/api/builds.json',
        "-F file=@#{package_file}",
        ("-F dsym=@#{zipped_dsym_path}" if dsym_path),
        "-F api_token='#{(ENV['TESTFLIGHT_API_TOKEN'] || @api_token)}'",
        "-F team_token='#{@team_token}'",
        "-F notes=@#{message_file_path}",
        "-F notify=#{(ENV['NOTIFY'] || notify).to_s.downcase.capitalize}",
        ("-F distribution_lists='#{distribution_list}'" if distribution_list)
      ].compact.join(' ')
    end
  end
end
