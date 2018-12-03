[#-- MOBILENOTIFIER --]

[#-- Components --]
[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotiferplatform" ]

[#-- Engines --]
[#assign MOBILENOTIFIER_SMS_ENGINE = "SMS" ]
[#assign componentConfiguration +=
    {
        MOBILENOTIFIER_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A managed mobile notification proxy"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "SuccessSampleRate",
                    "Type" : STRING_TYPE,
                    "Default" : "100"
                },
                {
                    "Names" : "Credentials",
                    "Children" : [
                        {
                            "Names" : "EncryptionScheme",
                            "Type" : STRING_TYPE,
                            "Values" : ["base64"],
                            "Default" : "base64"
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE,
                    "Component" : "Platforms",
                    "Link" : [ "Platform" ]
                }
            ]
        },
        MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A specific mobile platform notification proxy"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                },
                {
                    "Type" : "Note",
                    "Value" : "SMS Engine requires account level configuration for AWS provider",
                    "Severity" : "warning"
                },
                {
                    "Type" : "Note",
                    "Value" : "Platform specific credentials are required and must be provided as credentials",
                    "Severity" : "info"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "SuccessSampleRate",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Credentials",
                    "Children" : [
                        {
                            "Names" : "EncryptionScheme",
                            "Type" : STRING_TYPE,
                            "Values" : ["base64"]
                        }
                    ]
                },
                { 
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "LogMetrics",
                    "Subobjects" : true,
                    "Children" : logMetricChildrenConfiguration
                }
            ]
        }
    }]

[#function getMobileNotifierState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local result =
        {
            "Resources" : {
                "role" : {
                    "Id" : formatDependentRoleId( core.Id ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
    [#return result ]
[/#function]

[#function formatMobileNotifierLogGroupId engine name failure=false]
    [#local failureId = valueIfTrue("failure", failure, "") ]
    [#return
        valueIfTrue(
            formatAccountLogGroupId("sms", failureId),
            engine == MOBILENOTIFIER_SMS_ENGINE,
            formatLogGroupId(name, failureId)
        ) ]
[/#function]

[#function getMobileNotifierPlatformState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE, core.Id) ]
    [#local name = core.FullName ]
    [#local topicPrefix = core.ShortFullName]
    [#local engine = solution.Engine!core.SubComponent.Name?upper_case  ]

    [#local lgId = formatMobileNotifierLogGroupId(engine, name, false) ]
    [#local lgFailureId = formatMobileNotifierLogGroupId(engine, name, true) ]
    [#local result =
        {
            "Resources" : {
                "platformapplication" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Engine" : engine,
                    "Type" : AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : lgId,
                    "Name" : formatMobileNotifierLogGroupName(engine, name, false),
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "lgfailure" : {
                    "Id" : lgFailureId,
                    "Name" : formatMobileNotifierLogGroupName(engine, name, true),
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "ARN" : (engine == MOBILENOTIFIER_SMS_ENGINE)?then(
                            formatArn(
                                regionObject.Partition,
                                "sns",
                                regionId,
                                accountObject.AWSId,
                                "smsPlaceHolder"
                            ),
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE)
                ),
                "ENGINE" : engine,
                "TOPIC_PREFIX" : topicPrefix
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + regionId + ".amazonaws.com",
                        "LogGroupIds" : [ lgId, lgFailureId ]
                    }
                },
                "Outbound" : {
                    "default" : "publish",
                    "publish" : (engine == MOBILENOTIFIER_SMS_ENGINE)?then(
                        snsSMSPermission(),
                        snsPublishPlatformApplication(name, engine, topicPrefix)
                    )
                }
            }
        }
    ]
    [#return result ]
[/#function]