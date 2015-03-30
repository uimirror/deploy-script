# deploy-script

Automation script to deploye an java/non java application from git to amazon AWS.

# Features

# Version V0

<ol>
 <li>Auto Project check out</li>
 <li>Create smart branching for each release</li>
 <li>Create smart branching for each release on git</li>
 <li>Auto java project build</li>
 <li>Create Binary Distrubations</li>
 <li>Push to AWS instance</li>
 <li>Deploye application at target</li>
 <li>Kill instances by port and pids</li>
<li>Utility Script for Status monitor</li>
</ol>

# Usage

Check out this project and run <pre>./autodeploy.sh -r uimirror/uim_api.git</pre>
<code>-r specifies the branch name to use</code>
<code>-h or --help for complete user guide</code>

in case of any issues while deploying at aws:
<pre>Manually login to aws client and run ./ec2deploy.sh</pre>

In case to kill any process by pid or port
<pre>Manually login to aws client, navigate to the project distrubution/scripts and run ./stop.sh -p port_numers_comma_seperated -i pid_comma_seperated</pre>

In case to check for the process status and PID statics
<pre>Either Manually login to aws client, navigate to the project scripts and run ./utilites.sh -p port_numer --pidfile pid_file_loc</pre>
<pre>Type ./utilites.sh -h for more usage information</pre>
<pre>Utility Script can be run from same or remote machiene, please check patameters for more info</pre>
# Supporting Platform

Currently its supporting on 
<ol>
 <li>Mac OSX</li>
 <li>entOS Linux release 7.0.1406 (Core) </li>
</ol>

