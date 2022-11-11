*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive
Library             Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download orders file
    Open the order robot website
    ${orders_details}=    Read orders file
    Place the order    ${orders_details}
    Zip all receipts
    Close open browser


*** Keywords ***
Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true

Open the order robot website
    #${url}=    Get Value From User    Enter URL
    ${url}=    Get Secret    website_URL
    Open Available Browser    ${url}[url]
    Maximize Browser Window
    Close the annoying modal

Close the annoying modal
    Click Button    css:.btn-dark

Read orders file
    ${orders_details}=    Read table from CSV    orders.csv    header=true
    RETURN    ${orders_details}

Place the order
    [Arguments]    ${orders_details}
    ${counter}=    Set Variable    ${1}
    ${error_occured}=    Set Variable    False
    FOR    ${order_details}    IN    @{orders_details}
        TRY
            Log    ${counter}
            Select From List By Value    id:head    ${order_details}[Head]
            Select Radio Button    body    ${order_details}[Body]
            Input Text    css:.form-control    int(${order_details}[Legs])
            Input Text    id:address    ${order_details}[Address]
            Click Button    id:preview
            Sleep    1s
            Click Button    id:order
            Sleep    2s
            ${error_occured}=    Is Element Visible    css:div.alert-danger
            Log    ${error_occured}
            ${receipt_details}=    Capture order details    ${order_details}[Order number]
            ${screenshot_details}=    Take robot screenshot    ${order_details}[Order number]
            Embeded receipt and robot screenshot
            ...    ${order_details}[Order number]
            ...    ${receipt_details}
            ...    ${screenshot_details}
            Click Button    id:order-another
            Wait Until Element Is Visible    css:.btn-dark
            Close the annoying modal
            ${counter}=    Evaluate    ${counter}+${1}
        EXCEPT
            Sleep    1s
            WHILE    ${error_occured}
                Sleep    2s
                Click Button    id:order
                Sleep    1s
                ${error_occured}=    Is Element Visible    css:div.alert-danger
                Log    ${error_occured}
            END
            Sleep    1s
            ${receipt_details}=    Capture order details    ${order_details}[Order number]
            ${screenshot_details}=    Take robot screenshot    ${order_details}[Order number]
            Embeded receipt and robot screenshot
            ...    ${order_details}[Order number]
            ...    ${receipt_details}
            ...    ${screenshot_details}
            Click Button    id:order-another
            Wait Until Element Is Visible    css:.btn-dark
            Close the annoying modal
            ${counter}=    Evaluate    ${counter}+${1}
        END
    END

Capture order details
    [Arguments]    ${order_number}
    ${receipt_details}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt_details}    ${OUTPUT_DIR}${/}reciepts${/}${order_number}.Pdf    overwrite=true
    RETURN    ${OUTPUT_DIR}${/}reciepts${/}${order_number}.Pdf

Take robot screenshot
    [Arguments]    ${order_number}
    ${screenshot_details}=    Capture Element Screenshot
    ...    css:div#robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png

Embeded receipt and robot screenshot
    [Arguments]    ${order_number}    ${pdf}    ${image_details}
    ${receipt_pdf}=    Open Pdf    ${pdf}
    ${screenshot_details}=    Create List    ${pdf}    ${image_details}
    Add Files To Pdf    ${screenshot_details}    ${OUTPUT_DIR}${/}reciepts${/}${order_number}.Pdf
    Close Pdf    ${receipt_pdf}

Zip all receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}reciepts    ${OUTPUT_DIR}${/}Receipts.zip    overwrite=true

Close open browser
    Close Browser
