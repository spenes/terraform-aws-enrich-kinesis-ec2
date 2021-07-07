locals {
  resolvers_raw = concat(var.default_iglu_resolvers, var.custom_iglu_resolvers)

  resolvers_open = [
    for resolver in local.resolvers_raw : merge(
      {
        name           = resolver["name"],
        priority       = resolver["priority"],
        vendorPrefixes = resolver["vendor_prefixes"],
        connection = {
          http = {
            uri = resolver["uri"]
          }
        }
      }
    ) if resolver["api_key"] == ""
  ]

  resolvers_closed = [
    for resolver in local.resolvers_raw : merge(
      {
        name           = resolver["name"],
        priority       = resolver["priority"],
        vendorPrefixes = resolver["vendor_prefixes"],
        connection = {
          http = {
            uri    = resolver["uri"]
            apikey = resolver["api_key"]
          }
        }
      }
    ) if resolver["api_key"] != ""
  ]

  resolvers = flatten([
    local.resolvers_open,
    local.resolvers_closed
  ])

  iglu_resolver = jsonencode(templatefile("${path.module}/templates/iglu_resolver.json.tmpl", { resolvers = jsonencode(local.resolvers) }))

  campaign_attribution     = var.enrichment_campaign_attribution == "" ? jsonencode(file("${path.module}/templates/enrichments/campaign_attribution.json")) : var.enrichment_campaign_attribution
  event_fingerprint_config = var.enrichment_event_fingerprint_config == "" ? jsonencode(file("${path.module}/templates/enrichments/event_fingerprint_config.json")) : var.enrichment_event_fingerprint_config
  referer_parser           = var.enrichment_referer_parser == "" ? jsonencode(file("${path.module}/templates/enrichments/referer_parser.json")) : var.enrichment_referer_parser
  ua_parser_config         = var.enrichment_ua_parser_config == "" ? jsonencode(file("${path.module}/templates/enrichments/ua_parser_config.json")) : var.enrichment_ua_parser_config
  yauaa_enrichment_config  = var.enrichment_yauaa_enrichment_config == "" ? jsonencode(file("${path.module}/templates/enrichments/yauaa_enrichment_config.json")) : var.enrichment_yauaa_enrichment_config

  # Note: Used to trigger deployments when enrichments or resolvers change
  config_hash = md5(<<EOF
${local.iglu_resolver}
${local.campaign_attribution}
${local.event_fingerprint_config}
${local.referer_parser}
${local.ua_parser_config}
${local.yauaa_enrichment_config}
${var.enrichment_anon_ip}
${var.enrichment_api_request_enrichment_config}
${var.enrichment_cookie_extractor_config}
${var.enrichment_currency_conversion_config}
${var.enrichment_http_header_extractor_config}
${var.enrichment_iab_spiders_and_bots_enrichment}
${var.enrichment_ip_lookups}
${var.enrichment_javascript_script_config}
${var.enrichment_pii_enrichment_config}
${var.enrichment_sql_query_enrichment_config}
${var.enrichment_weather_enrichment_config}
EOF
  )
}

resource "aws_dynamodb_table_item" "iglu_resolver" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_resolver"},
  "json": {"S": ${local.iglu_resolver}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_campaign_attribution" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_campaign_attribution"},
  "json": {"S": ${local.campaign_attribution}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_event_fingerprint_config" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_event_fingerprint_config"},
  "json": {"S": ${local.event_fingerprint_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_referer_parser" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_referer_parser"},
  "json": {"S": ${local.referer_parser}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_ua_parser_config" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_ua_parser_config"},
  "json": {"S": ${local.ua_parser_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_yauaa_enrichment_config" {
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_yauaa_enrichment_config"},
  "json": {"S": ${local.yauaa_enrichment_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

# --- Non-default enrichments

resource "aws_dynamodb_table_item" "enrichment_anon_ip" {
  count = var.enrichment_anon_ip == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_anon_ip"},
  "json": {"S": ${var.enrichment_anon_ip}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_api_request_enrichment_config" {
  count = var.enrichment_api_request_enrichment_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_api_request_enrichment_config"},
  "json": {"S": ${var.enrichment_api_request_enrichment_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_cookie_extractor_config" {
  count = var.enrichment_cookie_extractor_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_cookie_extractor_config"},
  "json": {"S": ${var.enrichment_cookie_extractor_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_currency_conversion_config" {
  count = var.enrichment_currency_conversion_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_currency_conversion_config"},
  "json": {"S": ${var.enrichment_currency_conversion_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_http_header_extractor_config" {
  count = var.enrichment_http_header_extractor_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_http_header_extractor_config"},
  "json": {"S": ${var.enrichment_http_header_extractor_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_iab_spiders_and_bots_enrichment" {
  count = var.enrichment_iab_spiders_and_bots_enrichment == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_iab_spiders_and_bots_enrichment"},
  "json": {"S": ${var.enrichment_iab_spiders_and_bots_enrichment}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_ip_lookups" {
  count = var.enrichment_ip_lookups == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_ip_lookups"},
  "json": {"S": ${var.enrichment_ip_lookups}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_javascript_script_config" {
  count = var.enrichment_javascript_script_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_javascript_script_config"},
  "json": {"S": ${var.enrichment_javascript_script_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_pii_enrichment_config" {
  count = var.enrichment_pii_enrichment_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_pii_enrichment_config"},
  "json": {"S": ${var.enrichment_pii_enrichment_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_sql_query_enrichment_config" {
  count = var.enrichment_sql_query_enrichment_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_sql_query_enrichment_config"},
  "json": {"S": ${var.enrichment_sql_query_enrichment_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}

resource "aws_dynamodb_table_item" "enrichment_weather_enrichment_config" {
  count = var.enrichment_weather_enrichment_config == "" ? 0 : 1

  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "id": {"S": "snowplow_enrichment_weather_enrichment_config"},
  "json": {"S": ${var.enrichment_weather_enrichment_config}}
}
ITEM

  depends_on = [aws_dynamodb_table.config]
}
