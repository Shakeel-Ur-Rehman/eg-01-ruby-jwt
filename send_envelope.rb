require './example_base'
require './ds_config'
require 'base64'

class SendEnvelope < ExampleBase

  @@ENVELOPE_1_DOCUMENT_1 = %(
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
      </head>
      <body style="font-family:sans-serif;margin-left:2em;">
        <h1 style="font-family: 'Trebuchet MS', Helvetica, sans-serif;"
              color: darkblue;margin-bottom: 0;">World Wide Corp</h1>
        <h2 style="font-family: 'Trebuchet MS', Helvetica, sans-serif;
              margin-top: 0px;margin-bottom: 3.5em;font-size: 1em;
              color: darkblue;">Order Processing Division</h2>
        <h4>Ordered by #{DSConfig.signer_name}</h4>
        <p style="margin-top:0em; margin-bottom:0em;">Email:  #{DSConfig.signer_email} </p>
        <p style="margin-top:0em; margin-bottom:0em;">Copy to: #{DSConfig.cc_name}, #{DSConfig.cc_email} </p>
        <p style="margin-top:3em;">
          Candy bonbon pastry jujubes lollipop wafer biscuit biscuit. Topping brownie sesame snaps
          sweet roll pie. Croissant danish biscuit soufflé caramels jujubes jelly. Dragée danish caramels lemon
          drops dragée. Gummi bears cupcake biscuit tiramisu sugar plum pastry.
          Dragée gummies applicake pudding liquorice. Donut jujubes oat cake jelly-o. Dessert bear claw chocolate
          cake gummies lollipop sugar plum ice cream gummies cheesecake.
        </p>
        <!-- Note the anchor tag for the signature field is in white. -->
        <h3 style="margin-top:3em;">Agreed: <span style="color:white;">**signature_1**</span></h3>
      </body>
    </html>
  )
  @@DOC_2_DOCX = 'World_Wide_Corp_Battle_Plan_Trafalgar.docx'
  @@DOC_3_PDF = 'World_Wide_Corp_lorem.pdf'


  def sendEnvelope
    # Check token will fetch an access_token if needbe.
    check_token

    # Create the envelope request
    envelope = DocuSign_eSign::EnvelopeDefinition.new({
      :emailSubject => "Please sign this document sent from Ruby SDK"})

    doc1 = DocuSign_eSign::Document.new({
      :documentBase64 => Base64.encode64(@@ENVELOPE_1_DOCUMENT_1),
      :name => "Order acknowledgement",
      :fileExtension => "html",
      :documentId => "1"})

    doc2 = DocuSign_eSign::Document.new({
      :documentBase64 => Base64.encode64(File.binread(File.join('data', @@DOC_2_DOCX))),
      :name => "Battle Plan",
      :fileExtension => "docx",
      :documentId => "2"})

    doc3 = DocuSign_eSign::Document.new({
      :documentBase64 => Base64.encode64(File.binread(File.join('data', @@DOC_3_PDF))),
      :name => "Lorem Ipsum",
      :file_Extension => "pdf",
      :documentId => "3"})

    # The order in the docs array determines the order in the envelope
    envelope.documents = [doc1, doc2, doc3]
    # create a signer recipient to sign the document, identified by name and email
    signer1 = DocuSign_eSign::Signer.new({
      :email => DSConfig.signer_email,
      :name => DSConfig.signer_name,
      :recipientId => "1",
      :routingOrder => "1"})
    # routingOrder (lower means earlier) determines the order of deliveries
    # to the recipients. Parallel routing order is supported by using the
    # same integer as the order for two or more recipients.

    # create a cc recipient to receive a copy of the documents, identified by name and email
    # We're setting the parameters via setters
    cc1 = DocuSign_eSign::CarbonCopy.new({
      :email => DSConfig.cc_email,
      :name => DSConfig.cc_name,
      :routingOrder => "2",
      :recipientId => "2"})

    # Create signHere fields (also known as tabs) on the documents,
    # We're using anchor (autoPlace) positioning
    #
    # The DocuSign platform searches throughout your envelope's
    # documents for matching anchor strings. So the
    # sign_here_2 tab will be used in both document 2 and 3 since they
    # use the same anchor string for their "signer 1" tabs.
    sign_here1 = DocuSign_eSign::SignHere.new({
      :anchorString => "**signature_1**",
      :anchorUnits => "pixels",
      :anchorXOffset => "20",
      :anchorYOffset => "10"})

    sign_here2 = DocuSign_eSign::SignHere.new({
      :anchorString => "/sn1/",
      :anchorUnits => "pixels",
      :anchorXOffset => "20",
      :anchorYOffset => "10"})

    # Tabs are set per recipient / signer
    tabs = DocuSign_eSign::Tabs.new
    tabs.sign_here_tabs = [sign_here1, sign_here2]
    signer1.tabs = tabs

    # Add the recipients to the envelope object
    recipients = DocuSign_eSign::Recipients.new({
      :signers => [signer1],
      :carbonCopies => [cc1]})
    envelope.recipients = recipients

    # Request that the envelope be sent by setting |status| to "sent".
    # To request that the envelope be created as a draft, set to "created"
    envelope.status = "sent"

    # Call the API method
    envelope_api = DocuSign_eSign::EnvelopesApi.new(@@api_client)
    result = envelope_api.create_envelope(@@account_id, envelope)
    result
  end
end
