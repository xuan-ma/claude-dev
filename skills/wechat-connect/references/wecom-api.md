# WeCom (企业微信) API Reference

Quick reference for the WeCom application API endpoints used by this skill.

## Base URL

```
https://qyapi.weixin.qq.com/cgi-bin/
```

## Authentication

All API calls (except gettoken) require an `access_token` query parameter.

### Get Access Token

```
GET /cgi-bin/gettoken?corpid={corpid}&corpsecret={secret}
```

**Response:**
```json
{
  "errcode": 0,
  "errmsg": "ok",
  "access_token": "accesstoken000001",
  "expires_in": 7200
}
```

Token is cached in `/tmp/wecom-token-cache.json` with a 60s safety margin before expiry.

## Send Message

### Send Application Message

```
POST /cgi-bin/message/send?access_token={token}
Content-Type: application/json
```

**Text message body:**
```json
{
  "touser": "UserID1|UserID2",
  "msgtype": "text",
  "agentid": 1000002,
  "text": {
    "content": "Your message content here"
  }
}
```

**Markdown message body:**
```json
{
  "touser": "UserID1",
  "msgtype": "markdown",
  "agentid": 1000002,
  "markdown": {
    "content": "# Title\n\n**bold** text"
  }
}
```

### Error Codes

| errcode | Meaning |
|---------|---------|
| 0 | Success |
| 40001 | Invalid access_token (expired or wrong) |
| 40003 | Invalid userid |
| 40013 | Invalid corpid |
| 40014 | Invalid access_token (malformed) |
| 41001 | Missing access_token |
| 42001 | access_token expired |
| 60011 | No privilege to access this API |
| 82001 | User not in agent's visible range |

## Callback Configuration

### URL Verification (GET)

WeCom sends a GET request to verify the callback URL:

```
GET /wecom/callback?msg_signature={sig}&timestamp={ts}&nonce={nonce}&echostr={encrypted_echostr}
```

**Verification steps:**
1. Sort token, timestamp, nonce, echostr alphabetically
2. Concatenate, SHA1 hash
3. Compare with msg_signature
4. If match: decrypt echostr with AES key, return plaintext

### Message Callback (POST)

WeCom POSTs encrypted XML to the callback URL:

```xml
<xml>
  <ToUserName><![CDATA[corpid]]></ToUserName>
  <Encrypt><![CDATA[base64_encrypted_message]]></Encrypt>
</xml>
```

**Decryption: AES-256-CBC**
- Key: Base64-decoded callback_aeskey (43 chars → 32 bytes)
- IV: First 16 bytes of the key
- Padding: PKCS#7 (last byte = pad length)

**Decrypted XML:**
```xml
<xml>
  <ToUserName><![CDATA[corpid]]></ToUserName>
  <FromUserName><![CDATA[UserID]]></FromUserName>
  <CreateTime>1690000000</CreateTime>
  <MsgType><![CDATA[text]]></MsgType>
  <Content><![CDATA[user's reply]]></Content>
  <MsgId>1234567890</MsgId>
  <AgentID>1000002</AgentID>
</xml>
```

## Rate Limits

- Token requests: 2000/day per secret
- Message send: 2000/minute per agent
- No official rate limit on callback receiving

## References

- [WeCom API Docs (Chinese)](https://developer.work.weixin.qq.com/document/path/90236)
- [Message Send API](https://developer.work.weixin.qq.com/document/path/90236)
- [Callback Configuration](https://developer.work.weixin.qq.com/document/path/90930)
