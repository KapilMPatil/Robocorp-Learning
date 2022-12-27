*** Settings ***
Documentation       Build and order your robot.

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Robocloud.Items
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Tasks ***
Build And Order robot
    Download Orders File
    #Open Available Browser    https://robotsparebinindustries.com
    ${secret} =    Get Secret    credentials
    Open Available Browser    ${secret}[APPLICATION_PATH]

    Wait Until Element Contains    xpath://a[(@href='#/robot-order')]    Order your robot!
    Click Element    xpath://a[(@href='#/robot-order')]
    ${orders} =    Get Orders
    FOR    ${order}    IN    @{orders}
        Click Button    xpath://button[(@class='btn btn-dark')]
        Fill the form    ${order}
    END
    Confirmation dialog

    Log    Done.
    [Teardown]    Clean up Activity


*** Keywords ***
Download Orders File
    ${secret} =    Get Secret    credentials
    Download    ${secret}[CSV_URL]    ${OUTPUT DIR}${/}downloads    True    False    True

Get Orders
    ${DataInput} =    Read table from CSV    ${OUTPUT DIR}${/}downloads
    RETURN    ${DataInput}

Close the annoying modal
    Click Button    xpath://button[(@class='btn btn-dark')]

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[(@placeholder='Enter the part number for the legs')]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Element Contains    robot-preview    Admire your robot!
    Click Button    order
    ${Is Error} =    Is Element Visible    alert alert-danger
    IF    ${True} == ${Is Error}    Click Button    order
    ${order-another} =    Is Element Visible    order-another
    WHILE    ${order-another} == ${False}
        Click Button    order
        ${order-another} =    Is Element Visible    order-another
    END
    Screenshot    order-completion    ${OUTPUT DIR}${/}${order}[Order number]_order-completion.png
    Screenshot    robot-preview-image    ${OUTPUT DIR}${/}${order}[Order number]_preview.png
    ${files} =    Create List
    ...    ${OUTPUT DIR}${/}${order}[Order number]_order-completion.png
    ...    ${OUTPUT DIR}${/}${order}[Order number]_preview.png
    Add Files To Pdf    ${files}    ${OUTPUT DIR}${/}OUTPUTPDF${/}${order}[Order number].pdf

    Click Button    order-another
    Wait Until Element Contains    xpath://button[(@class='btn btn-dark')]    OK

Compress PDF Files
    Archive Folder With Zip    ${OUTPUT DIR}${/}OUTPUTPDF    ${OUTPUT DIR}${/}mydocs.zip

Confirmation dialog
    Add heading    Do you want to Zip files
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result} =    Run dialog

    IF    $result.submit == "Yes"
        Compress PDF Files
    ELSE
        Log    Process comleted without zip operation.
    END

Clean up Activity
    Close Browser
