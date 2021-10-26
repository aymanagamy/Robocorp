*** Settings ***
Documentation   Orders Robots from RobotSpareBin Industries Inc
...             Saves the Order HTML receipts as PDF
...             Saves a screenshot of the ordered robot
...             Embeds the screenshot of the robot in the order PDF receipt
...             Creates a zip archive that contains all orders PDF receipts

Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.HTTP
Library    Dialogs
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Keywords ***
Order Robots from RobotSpareBin Industries Inc

*** Keywords ***
Open the Robot Order Website

    # 1. URL hardcoded     
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    
    # 2. Get URL through Vault
    ${secret}    Get Secret    RobotSpareBin
    Open Available Browser    ${secret}[url]

    Wait Until Page Contains Element    id:order

*** Keywords ***
Read CSV data
    # 1. Download CSV from portal
    # ${filepath}    https://robotsparebinindustries.com/orders.csv
    # Download   ${filepath}     overwrite=True
    # ${filepath}    orders.csv  
    
    # 2. Get CSV from user  
    ${filepath}    Prompt User for Input
    
    ${orders}=    Read table from CSV   ${filepath}
    Log    Found columns: ${orders.columns}
    [Return]    ${orders}

*** Keywords ***
Process Orders
    [Arguments]    ${data}

    FOR    ${row}    IN    @{data}
        Bypass Rights Alert
        Fill an Order    ${row}
        Preview the Order
        Wait Until Keyword Succeeds    5x    strict: 500ms    
         ...    Submit the Order
        ${receipt_path}    Store the Order Receipt as PDF    ${row}[Order number]
        ${image_path}    Take a Screenshot of the Order    ${row}[Order number]        
        Embed the Screenshot to the Order PDF    ${receipt_path}    ${image_path}
        Reset to a New Order
    END

Bypass Rights Alert
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    OK
    Wait Until Element Is Not Visible    class:alert-buttons

*** Keywords ***
Fill an Order
    [Arguments]    ${row}    
    Select From List By Value    id:head    ${row}[Head]        
    Click Element    id:id-body-${row}[Body]    action_chain=True    
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Sleep    500ms        # Adding 500ms as a safe margin for 'Legs' field because it is missing occasionally

*** Keywords ***
Preview the Order
    Wait Until Element Is Visible    id:preview
    Click Button    id:preview
    Wait Until Page Contains Element    id:robot-preview-image

Submit the Order
    Wait Until Element Is Visible    id:order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt       2s
    
*** Keywords ***
Reset to a New Order
    # Wait Until Page Contains Element    id:order-another
    Click Button    id:order-another    
    Wait Until Page Does Not Contain Element    id:order-another

*** Keywords ***
Take a Screenshot of the Order
    [Arguments]    ${ordernum}
    Wait Until Element Is Visible    id:receipt
    ${image_path}    Set Variable     ${CURDIR}${/}output${/}screenshots${/}order-${ordernum}.jpg
    Screenshot    id:receipt    ${image_path}
    [Return]    ${image_path}

*** Keywords ***
Store the Order Receipt as PDF
    [Arguments]    ${ordernum}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}    Get Element Attribute    id:receipt    outerHTML
    ${receipt_path}    Set Variable    ${CURDIR}${/}output${/}receipts${/}order-${ordernum}.pdf
    Html To Pdf    ${receipt_html}    ${receipt_path}
    [Return]    ${receipt_path}

*** Keywords ***
Embed the Screenshot to the Order PDF
    [Arguments]    ${receipt_path}    ${image_path}
    Open Pdf    ${receipt_path}
    Add Watermark Image To Pdf    ${image_path}    ${receipt_path}
    Close Pdf    ${receipt_path}

*** Keywords ***
Create a ZIP archive for all PDF Receipts    
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipts.zip

*** Keywords ***
Prompt User for Input
    Add heading    Get Input from User
    Add file input    fileupload
    ...    label=Path to CSV input file
    ${response}     Run dialog
    [Return]    ${response.fileupload}[0]
    
*** Keywords ***
Logout
    Close Browser

*** Tasks ***
Order Robots from RobotSpareBin Industries Inc
    Open the Robot Order Website
    ${data}    Read CSV data
    Process Orders   ${data}
    Create a ZIP archive for all PDF Receipts

Close and Log Completed
    [Teardown]    Logout
    Log  Done.
