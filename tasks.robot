*** Settings ***
Documentation     Orders robot from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${False}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           OperatingSystem
Library           RPA.RobotLogListener
Library           RPA.Dialogs

*** Variables ***
${URL}=           https://robotsparebinindustries.com/#/robot-order
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Clean Up
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the modal
        Fill order from    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot    ${row}[Order number]
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}    ORDER_NUMBER=${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Log Out And Close The Browser

*** Keywords ***
Directory Clean Up
    Log To Console    Cleaning up content from previous test runs
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Open the robot order website
    Log To Console    Opening robot order website
    Open Available Browser    url=${URL}

Get orders
    Log To Console    Downloading input file
    Download    ${csv_url}    target_file=${orders_file}    overwrite=${True}
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}

Close the modal
    Log To Console    Close the modal
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button    ${btn_yep}

Fill order from
    [Arguments]    ${myrow}
    Set Local Variable    ${order_no}    ${myrow}[Order number]
    Set Local Variable    ${head}    ${myrow}[Head]
    Set Local Variable    ${body}    ${myrow}[Body]
    Set Local Variable    ${legs}    ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}
    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}
    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}
    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    Log To Console    Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit The Order
    Log To Console    Submit The Order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]
    Mute Run On Failure    Page Should Contain Element
    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take a screenshot of the robot
    Log To Console    Take a screenshot
    [Arguments]    ${order_no}
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${order_no}.png
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}
    [Return]    ${orderid}    ${fully_qualified_img_filename}

Store the receipt as a PDF file
    Log To Console    Store PDF File
    [Arguments]    ${ORDER_NUMBER}
    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    [Return]    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    Log To Console    Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}    ${ORDER_NUMBER}
    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open PDF    ${PDF_FILE}
    @{myfiles}    Create List    ${IMG_FILE}    ${PDF_FILE}
    Add Files To Pdf    ${myfiles}    ${pdf_folder}${/}Order_No_${ORDER_NUMBER}.pdf
    Close PDF    ${PDF_FILE}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Log Out And Close The Browser
    Close Browser
