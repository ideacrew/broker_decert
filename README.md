# Required Inputs

You will need the following information to process the broker decertifications:

1. Confirmation that the broker has been removed from the affected family with the correct end date on the broker account
2. A CSV Containing:
  1. HBX ID of the impacted enrollment (column `hbx_enrollment_id`)
  2. Enrollment Group ID (from GlueDB) of the corresponding active policy (column `eg_id`)

# Steps

**BEFORE ANYTHING**: Update the secrets.rb file with username, password, and URI to AMQP server.

Remember to run all the Ruby scripts with `bundle exec ruby <scriptname>`.

1. Use the source CSV to extract a more-detailed CSV from gluedb, including member start dates (use the `extract_glue_policy_data.rb` script)
2. Extract source XMLs from enroll using the `connect_and_request.rb`, and then the `connect_and_download.rb` scripts and the source CSV
3. Enrich the XMLs using the `generate_broker_changes.rb` script
4. Transform the XMLs to X12 using the `encode_enrollments.rb` script
5. Use the `fix_amrc_for_publish.rb` script to update the AMRC and other associated properties to match that of a broker change in the X12 XMLs
6. Use the `` script to publish the X12s to the B2B endpoint for maintenance transactions
