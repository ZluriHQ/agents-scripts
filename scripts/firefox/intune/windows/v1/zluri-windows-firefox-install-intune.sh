$dest_folder = "C:\Program Files\Mozilla Firefox\distribution"
$json_content = '{
   "policies": {
     "EnterprisePoliciesEnabled": true,
     "ExtensionSettings": {
       "zluribrowseragent@zluri.com": {
         "installation_mode": "force_installed",
         "install_url": "https://addons.mozilla.org/firefox/downloads/file/4241546/zluri_web_extension_firefox-2.3.3.xpi"
       }
     }
   }
 }'


if (!(Test-Path -Path $dest_folder)) {
   New-Item -ItemType Directory -Path $dest_folder | Out-Null
}


$json_content | Set-Content -Path "$dest_folder\policies.json"