# 参考記事
# https://qiita.com/otakky/items/b7582202f5cde8f2dd21
class FirebaseIdTokenDecoder
  ALGORITHM = 'RS256'.freeze
  ID_TOKEN_ISSUER_PREFIX = 'https://securetoken.google.com/'.freeze
  ID_TOKEN_CERT_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'.freeze

  FIREBASE_PROJECT_ID = Rails.configuration.x.settings.firebase.project_id

  class FirebaseDecodeTokenError < StandardError; end

  def initialize(id_token)
    raise_decode_error('id token must be a String') unless id_token.is_a?(String)

    @id_token = id_token
    @kid = kid(id_token)
    raise_decode_error('Firebase ID token has no "kid" claim.') unless @kid

    @certificate = identify_certificate(@kid)
  end

  def decode
    option = { algorithm: ALGORITHM, verify_iat: true }
    payload, header = decode_token(@id_token, @certificate.public_key, true, option)
    validate_jwt(payload, header)

    {
      'payload' => payload,
      'header' => header
    }
  end

  private

  def identify_certificate(kid)
    @public_keys ||= fetch_public_keys
    public_key = @public_keys[kid]
    unless public_key
      raise_decode_error <<~MSG.squish
        Firebase ID token has "kid" claim which does not correspond to
        a known public key. Most likely the ID token is expired, so get a fresh token from your client
        app and try again.
      MSG
    end

    OpenSSL::X509::Certificate.new(public_key)
  end

  def fetch_public_keys
    # TODO: 毎回fetchしないようにする
    response = HTTParty.get(ID_TOKEN_CERT_URI)
    raise_decode_error("couldn't fetch public keys") if response.code != 200

    response.to_h
  end

  def kid(token)
    header, * = token.split('.')
    header_json = Base64.urlsafe_decode64(header)
    header_hash = JSON.parse(header_json)
    header_hash['kid']
  end

  def decode_token(token, key, verify, options)
    begin
      payload, header = JWT.decode(token, key, verify, options)
    rescue JWT::ExpiredSignature
      raise_decode_error('Firebase ID token has expired.')
    rescue JWT::VerificationError
      raise_decode_error('Firebase ID token has invalid signature.')
    rescue StandardError => e
      raise_decode_error("There is a problem with the Firebase ID token: #{e.message}")
    end
    [payload, header]
  end

  def validate_jwt(payload, header)
    validate_alg(header['alg'])
    validate_aud(payload['aud'])
    validate_iss(payload['iss'])
    validate_sub(payload['sub'])
  end

  def validate_alg(alg)
    return if alg == ALGORITHM

    raise_decode_error <<~MSG.squish
      Firebase ID token has incorrect algorithm.
      Expected "#{ALGORITHM}" but got "#{alg}".
    MSG
  end

  def validate_aud(aud)
    return if aud == FIREBASE_PROJECT_ID

    raise_decode_error <<~MSG.squish
      Firebase ID token has incorrect "aud" (audience) claim.
      Expected "#{FIREBASE_PROJECT_ID}" but got "aud".
    MSG
  end

  def validate_iss(iss)
    issuer = "#{ID_TOKEN_ISSUER_PREFIX}#{FIREBASE_PROJECT_ID}"
    return if iss == issuer

    raise_decode_error <<~MSG.squish
      Firebase ID token has incorrect "iss" (issuer) claim.
      Expected "#{issuer}" but got "#{iss}".
    MSG
  end

  def validate_sub(sub)
    raise_decode_error('Firebase ID token has no "sub" (subject) claim.') if sub.nil?
    raise_decode_error('Firebase ID token has an empty string "sub" (subject) claim.') if sub.empty?
    if sub.size > 128
      raise_decode_error('Firebase ID token has "sub" (subject) claim longer than 128 characters.')
    end
  end

  def raise_decode_error(message)
    raise FirebaseDecodeTokenError, message
  end
end
