[#-- Private DNS zone --]
[#if slice?contains("dns")]
    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            "dns" : {
                "Type" : "AWS::Route53::HostedZone",
                "Properties" : {
                    "HostedZoneConfig" : {
                        "Comment" : "${productName}-${segmentName}" 
                    },
                    "HostedZoneTags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "Name" : "${segmentName}.${productName}.internal",
                    "VPCs" : [                
                        { "VPCId" : "${getKey("vpcXsegmentXvpc")}", "VPCRegion" : "${regionId}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "dnsXsegmentXdns" : {
                "Value" : { "Ref" : "dns" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]
