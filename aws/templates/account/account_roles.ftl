[#-- Account level roles --]
[#if deploymentUnit?contains("roles")]
    [#if resourceCount > 0],[/#if]
    [#assign automationRoleId = formatAccountRoleId("automation")]
    [#assign administratorRoleId = formatAccountRoleId("administrator")]
    [#assign viewerRoleId = formatAccountRoleId("viewer")]

    [#switch accountListMode]
        [#case "definition"]            
            [#assign accessAccounts=[]]
            [#list accountObject.Access?values as accessAccount]
                [#if accessAccount?is_hash]
                    [#assign accessAccounts += [accessAccount.AWSId]]
                [/#if]
            [/#list]
            [@role
                id=automationRoleId
                name="codeontap-automation"
                trustedAccounts=accessAccounts
                managedArns=
                    [
                        "arn:aws:iam::aws:policy/AdministratorAccess"
                    ]
            /],
            [@role
                id=administratorRoleId
                name="codeontap-administrator"
                trustedAccounts=accessAccounts
                managedArns=
                    [
                        "arn:aws:iam::aws:policy/AdministratorAccess"
                    ]
                multiFactor=true
            /],
            [@role
                id=viewerRoleId
                name="codeontap-viewer"
                trustedAccounts=accessAccounts
                managedArns=
                    [
                        "arn:aws:iam::aws:policy/ReadOnlyAccess"
                    ]
                multiFactor=true
            /]
            [#break]
        
        [#case "outputs"]
            [@output automationRoleId /],
            [@outputArn automationRoleId /],
            [@output administratorRoleId /],
            [@outputArn administratorRoleId /],
            [@output viewerRoleId /],
            [@outputArn viewerRoleId /]
            [#break]

    [/#switch]        
    [#assign resourceCount += 1]
[/#if]

