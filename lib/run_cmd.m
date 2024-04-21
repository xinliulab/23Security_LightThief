function run_cmd(cmd_string, env_string)
    if nargin >1 
        for ii=1:2:length(env_string)
            setenv(env_string{ii}, env_string{ii+1});
        end
    end
    [status] = system(cmd_string);
    assert(status==0, sprintf("Command Failed\n%s\n",cmd_string))
end