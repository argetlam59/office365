# office365
27/03/2022 - ss

I have updated the Hands off 365 script; After some though I have descided that I am not going to be doing any more updates to the 365 security defaults script and instead will be focusing on ensuring that the hands off script is a, user friendly and b, level 1 tech friendly. Aim of the game is your newest tech should be able to sit there and run this script. 
Added 
* Get-InstalledMod check - It will now check for dependent modules and install them if they are missing. 
* Changed some of the regions and made it simpler to follow through the functions and such at the top of the script. 
* I also Added the DKIM files that I have. Not sure if I deleted them earlier or if I just never bought them to the public. 
TODO: 
* Comment out the lines from the script so that people can adjust more settings that they want to. 
* Possibly functionify some of the settings so that people can add switches in or change the settings a little easier, still thinking about this one. 
* Use Graph more, We should be able to do more with the secureApp method. 

NOTE: You should look at CIPP (https://cipp.app/) This does everything the script does but better. Kelvin and his team have made this a fairly great product and you should be able to use your azure credits from partner to be able to pay for the hosting for the site. Personally, I think this will be the future standard for multi tenent managment. 

15/02/2021 - ss

Uploaded hands off 365 security defaults. Same as the other 365 but without all the constant popups. 

09/08/2021 - ss

Uploaded the chrome notification script. Should have tested to see if it runs as local user or if you need admin. 99% sure that you are going to need to run it as admin which makes me think I should just elevete the script at the beginning. But please if you run into issues with the script please let me know. 

29/06/2021 - ss

I updated the 365 script to include a couple of transport rules. These could have been done in other places however I like using the transport rules as they are pretty simple if statments that do what they are told. Please be careful with the TLD filter. It has capacity to block legitimate emails. This was made in the mind set of a Australian company that doesn't deal with alot of overseas companies or domains. 

19/06/2021 - ss

Updated the 365 security script to make it a little easier for people to drop and play. 
Changed variables on the 365 script so that it can be used on the go. You can also just statically assign these so that they just stay put and you don't have to go and reenter these every time. 

14/12/2020 - ss

Added MapEmail_Without_automap.ps1
Found that to many mailboxes made my computer sad when I opened outlook. So by going through and changing all the mailboxes to not automap to outlook, means I only get the mailboxes that I actually want through to my outlook profile. 
