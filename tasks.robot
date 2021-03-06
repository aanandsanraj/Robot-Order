*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library     RPA.Browser
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.JSON
Library     Dialogs
Library     RPA.Robocloud.Secrets


*** Keywords ***
Open the robot order website
    ${vault_json}=      Get Secret    weburl
    Log     ${vault_json}[url]
    Open Available Browser      ${vault_json}[url]
    Maximize Browser Window

*** Keywords ***
Get Orders
    ${csv_url}=     Get Value From User     Please enter the csv url     https://robotsparebinindustries.com/orders.csv
    Download    ${csv_url}      overwrite=True
    ${orders}=      Read Table From Csv    orders.csv
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Click Button    css:button[class="btn btn-dark"]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Index       id:head     ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]   ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible     id:robot-preview-image    3000ms

*** Keywords ***
Submit the order
    FOR    ${i}    IN RANGE    100
        ${receipt_exists}       Is Element Visible      id:receipt
        IF    ${receipt_exists} == False
            Click Button    id:order
        ELSE
            Exit For Loop
        END
    END
    Wait Until Element Is Visible    id:receipt     3000ms

*** Keywords ***
Loop and click


*** Keywords ***
Store receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=       Get Element Attribute    id:receipt    outerHTML
    ${receipt_pdf}=     Set Variable        ${CURDIR}${/}output${/}order_receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}     ${receipt_pdf}
    [Return]    ${receipt_pdf}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${order_number}
    ${screenshot}=      Set Variable    ${CURDIR}${/}output${/}order_${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot}
    [Return]    ${screenshot}

***** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}    ${pdf}
    ${file_list}    Create List     ${pdf}      ${screenshot}:align=center
    Add Files To Pdf    ${file_list}    ${pdf}
    Sleep     1500ms

*** Keywords ***
Go to order another robot
    Click Button    id:order-another
    Sleep     500ms

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output{/}    robot_order.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=      Get Orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form   ${row}
        Preview the robot
        Submit the order
        ${pdf}=      Store receipt as a PDF file     ${row}[Order number]
        ${screenshot}=      Take a screenshot of the robot      ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close Browser


