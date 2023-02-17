*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault

Test Setup          Clear PDF and img folders
Test Teardown       Close All Browsers


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Use Vault
    # ${user}    Get The User Name        # Commented because there's issue with pywebview in cloud
    Open Available Browser    url=https://robotsparebinindustries.com/
    Download the Order file
    ${table}    Read CSV File
    Open Ordering Form
    FOR    ${ROW}    IN    @{table}
        Close annoying popup
        Build robot    ${ROW}
        Order the robot
        ${order_id}    Get order number
        ${picture}    Take screenshot from Ordered Robot    ${order_id}
        ${pdf}    Get Sales receipt as PDF    ${order_id}    ${picture}
        Click Button    id:order-another
    END
    Create a Zip file with the receipts


*** Keywords ***
Get The User Name
    Add heading    Please, provide a name for this run:
    Add text input    name    label=Enter your name here
    ${result}    Run dialog
    Log    ${result.name} has started the robot!
    RETURN    ${result.name}

Build robot
    [Arguments]    ${row}
    Set Local Variable    ${order_no}    ${row}[Order number]
    Set Local Variable    ${head}    ${row}[Head]
    Set Local Variable    ${body}    ${row}[Body]
    Set Local Variable    ${legs}    ${row}[Legs]
    Set Local Variable    ${address}    ${row}[Address]
    Wait Until Element Is Enabled    id:head
    Select From List By Value    //*[@id="head"]    ${head}
    Select Radio Button    body    ${body}
    Input Text    class:form-control    ${legs}
    Input Text    id:address    ${address}
    Click Button    id:preview

Order the robot
    Wait Until Element Is Enabled    class:btn-primary
    Click Button    class:btn-primary

    ${status}    Run Keyword And Return Status    Get Text    class:alert-danger
    WHILE    '${status}' != 'False'
        Click Button    class:btn-primary
        ${status}    Run Keyword And Return Status    Get Text    class:alert-danger
    END

Get Sales receipt as PDF
    [Arguments]    ${order_id}    ${picture}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}pdf${/}${order_id}.pdf
    Open Pdf    ${OUTPUT_DIR}${/}pdf${/}${order_id}.pdf
    ${picture_as_a_list}    Create List
    ...    ${picture}
    Add Files To Pdf    ${picture_as_a_list}    ${OUTPUT_DIR}${/}pdf${/}${order_id}.pdf
    Close Pdf    ${OUTPUT_DIR}${/}pdf${/}${order_id}.pdf
    RETURN    ${OUTPUT_DIR}${/}pdf${/}${order_id}.pdf

Take screenshot from Ordered Robot
    [Arguments]    ${order_id}
    Wait Until Page Contains Element    id:robot-preview-image
    ${picture}    Capture Element Screenshot    id:robot-preview-image    ${OUTPUTDIR}/img/robot-image-${order_id}.png
    RETURN    ${picture}

Get order number
    Wait Until Page Contains Element    class:badge-success
    ${order_id}    Get Text    class:badge-success
    RETURN    ${order_id}

Open Ordering form
    Click Element    xpath://a[contains(text(),'Order your robot!')]

Read CSV File
    ${table}    Read table from CSV    orders.csv
    RETURN    ${table}

Download the Order file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Close annoying popup
    ${status}    Run Keyword And Return Status    Is Element Visible    class:btn-dark
    IF    '${status}' == 'True'    Click Element    class:btn-dark

Create a Zip file with the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}/pdf    ${OUTPUT_DIR}${/}pdf_archive.zip    include=*.pdf

Clear PDF and img folders
    Run Keyword And Ignore Error    Empty Directory    ${OUTPUT_DIR}/pdf
    Run Keyword And Ignore Error    Empty Directory    ${OUTPUT_DIR}/img

Use Vault
    ${secret}    Get Secret    myfirstpet
    Log    My ${secret}[petname] is very lovable.
