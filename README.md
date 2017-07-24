# appdynamics-alerting-extension
ActionScript to provide meaningful information from AppDynamics platform

## Installation

Simplest method (_only if you don't already have a custom.xml_):

1. Download the latest release from [here](https://github.com/SignifAi/appdynamics-alerting-extension/releases)
2. Unzip in your controller directory (e.g. if you installed to your home directory,
   /home/user/appdynamics/controller )
3. Edit custom/actions/signifai/params.sh with your URL (given in the Sensors page for AppDynamics) 
4. Restart AppDynamics (`/home/user/appdynamics/controller/bin/stopController.sh && 
   /home/user/appdynamics/controller/bin/startController.sh`)

If you _do_ have a custom xml in custom/actions, just don't replace it with the one in the release ZIP file,
but instead add these lines between your `<custom-actions>` tags:

```
  <action>
    <type>signifai</type>
    <executable>notify.sh</executable>
  </action>
```

Make sure custom/actions/signifai and all our shellscript files are present, and
then restart AppDynamics as demonstrated above. 

