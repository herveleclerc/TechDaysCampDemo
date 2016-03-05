#!/bin/bash

echo "docker stack will be deployed by this script"

              {
                "name": "LinuxDiagnostic",
                "properties": {
                  "publisher": "Microsoft.OSTCExtensions",
                  "type": "LinuxDiagnostic",
                  "typeHandlerVersion": "2.1",
                  "autoUpgradeMinorVersion": false,
                  "settings": {
                    "xmlCfg": "[base64(concat(variables('wadcfgxstart'),variables('wadmetricsresourceid'),variables('wadcfgxend')))]",
                    "storageAccount": "[variables('diagnosticsStorageAccountName')]"
                  },
                  "protectedSettings": {
                    "storageAccountName": "[variables('diagnosticsStorageAccountName')]",
                    "storageAccountKey": "[listkeys(variables('accountid'), variables('apiVersion')).key1]",
                    "storageAccountEndPoint": "https://core.windows.net"
                  }
                }
              }