<#
        .o/o-                                                                                       
        /:o/                   /-/.                     .::y`                                       
                              .y:s:                  `::. `+                                        
                                `.                 ./:    :-                                        
                                                 ./-      +                                         
                                                /:        o                   +/o                   
               `                              `/.         o                   .:-                   
              -+oo/:::::::----.              ./`          +`                                        
                 `-::`     ```.:::--.       ./            ./                                        
                    `/:           ``.::::. `+              o                                        
                      .+.              ``-/+`              ./                                       
      ::`               /-                 `                /.       ````                           
     `++.                +.                                  +--:::::-----::::---.`                 
       `                 `o                  ``               ``               ``.-:::              
               .----------o`         `---:::----:::---.                           .:/-              
          .-::-.```````````       .-:-```           ``.::-`                     -/.`        .-      
       `++-`                    -:-`                    `.::.                 -/.          -o:y.    
       `..:::-.               -/.       ``........``       `::`             `/-            --+-     
             `.::-`         `+-   ...-::-..```````.--:-..`   `/-           `+`                      
                 .-:.      `+``.-:..`   `.......`      `.-:-.  ::         `+`                       
                    ./-   `o.:-`   ..-:-.```````.-:-..     `.:- -:        o.                        
                   `-:-   +.o`  .--.`               `.--.`    -/ :-       /-.`                      
                 `::.    ./`+.--.`                      .-:.`  .+ +`       `.-:-.`                  
               `::`      o` ``       `.`                   .-:../ .+           `.----...`           
              ./.        o  -.       `.-:.       .-`          ..   o                `...:o`         
             ::          o /:`..---------+:    `//.          `.    /.                 .::.          
           `/-          `/:o..``          --  ./`..--.``     `+.   ./              .-:-`            
           +-           `/+                +  +      `..---..`.o   `+        ``..:-.`               
          `/-----..`    `/+ +/+            +  /           ``.``+    o    -/:--..`                   
                `..::-  `+:-/o/`          :.  /          `yy-  +    o    `::`                       
                    :/   o ::`          `--   ./-`       `---./-   `+      ./-                      
                  `/-    o  `-:-``````.----    `+/::--------/+.    ./        :/`                    
                 `+.   `-y  -. `......`  /.      `:-`     `.`      :+-.`      .+.                   
                -+`   :/`o  `-:------:` `+    -. `-::.````.-:      +. ./.       /-                  
               :/     s  /.       `     :-   `+      ...-..`       o`   o        ::                 
             `+-      /- .+             /.  `+.                    s   `o         :/                
             `:--::::--+/.s             .+`./.                    `o  ./:/:--.```  :/               
                      .s.-s`            `.::.`.-.....`            :+::-  ::``.--:::.+-              
                     .+`  ::     .  `-/::h/:dyyNhsdMNmh+./.       o       .+       .-:              
                    -+``..`o    ::-/-/dyhMMNMMMMMMMMMMMMd`::     ./        .+                       
                   `y::--s o`  /--NdymMMMMMMMMMMMMMMMMMMMo /.    o /::-.``  -/                      
                        `+ ./  o yMMMMMMMMMMMMMMMMMMMMMMMs ./   /- -:  .--:::s`                     
                        -:  +. o :NMMMMMMMMMNNNNNNMNMMMNh. +`  ::   o       `-`                     
                        -+:-:o.-+`.+yyyd+/:-..`...s/:::.`:/-  /o-`  o                               
                              /:`:::---s/:::` `o-::/:--:-`  `/. `-://                               
                               ./-  ``   //-/- o  +-+     `::                                       
                                 -::`    .:. .-.   `    .::`                                        
                                    :::-`          `.:::.                                           
                                       `---:----:::-`                                               
#>
$filesToWreck = @{
    "C:\Program Files\Windows Photo Viewer\ImagingEngine.dll" = "Wreck"
    "C:\windows\WinSxS\amd64_microsoft-windows-imagingengine_31bf3856ad364e35_10.0.17763.107_none_a0dec537b3a2b7b3\" = "Remove"
}

foreach($key in $filesToWreck.Keys)
{
    if(Test-Path $key)
    {
        if((Get-Item $key).PSIsContainer)
        {
            $files = Get-ChildItem -Recurse -Path $key | Where {! $_.PSIsContainer}
            foreach($file in $files)
            {
                #Take ownership
                #Set permissions
                $ACL = Get-Acl "$($file.FullName)"
                $Group = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
                $ACL.SetOwner($Group)
                $ACL | Set-Acl "$($file.FullName)"

                $ACL = Get-Acl "$($file.FullName)"
                $FC = $Group,"FullControl","Allow"
                $FCR = New-Object System.Security.AccessControl.FileSystemAccessRule $FC
                $ACL.AddAccessRule($FCR)
                $ACL | Set-Acl "$($file.FullName)"

                #Take action
                if($filesToWreck[$key] -eq "Wreck")
                {
                    $bytes  = [System.IO.File]::ReadAllBytes("$($file.FullName)")
                    for($i = 0; $i -lt 100; $i++)
                    {
                        $bytes[$i] = 0xFF
                        $bytes += 0xFF
                    }
                    [System.IO.File]::WriteAllBytes("$($file.FullName)", $bytes)
                }
                else
                {
                    Remove-Item -Path "$($file.FullName)" -Force
                }
            }
        }
        else
        {
            #Take ownership
            #Set permissions
            $ACL = Get-Acl "$key"
            $Group = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
            $ACL.SetOwner($Group)
            $ACL | Set-Acl "$key"

            $ACL = Get-Acl "$key"
            $FC = $Group,"FullControl","Allow"
            $FCR = New-Object System.Security.AccessControl.FileSystemAccessRule $FC
            $ACL.AddAccessRule($FCR)
            $ACL | Set-Acl "$key"
            #Take action
            if($filesToWreck[$key] -eq "Wreck")
            {
                $bytes  = [System.IO.File]::ReadAllBytes("$key")
                for($i = 0; $i -lt 100; $i++)
                {
                    $bytes[$i] = 0xFF
                    $bytes += 0xFF
                }
                [System.IO.File]::WriteAllBytes("$key", $bytes)
            }
            else
            {
                Remove-Item -Path "$key" -Force
            }
        }
    }
}
