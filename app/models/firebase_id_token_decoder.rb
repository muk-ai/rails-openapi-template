# 参考記事
# https://qiita.com/otakky/items/b7582202f5cde8f2dd21
class FirebaseIdTokenDecoder
  ALGORITHM = 'RS256'.freeze
  ID_TOKEN_ISSUER_PREFIX = 'https://securetoken.google.com/'.freeze
  ID_TOKEN_JWK_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'

  FIREBASE_PROJECT_ID = Rails.configuration.x.settings.firebase.project_id

  class FirebaseDecodeTokenError < StandardError; end

  def initialize(id_token)
    raise_decode_error('id token must be a String') unless id_token.is_a?(String)

    @id_token = id_token
    @jwks = fetch_jwks
  end

  def decode
    header, payload = decode_id_token(@id_token, @jwks)
    validate(payload)

    {
      'header' => header,
      'payload' => payload,
    }
  end

  private

  def fetch_jwks
    # TODO: 毎回fetchしないようにする
    response = HTTParty.get(ID_TOKEN_JWK_URL)
    raise_decode_error("couldn't fetch jwks") if response.code != 200

    response.to_h
  end

  def decode_id_token(id_token, jwks)
    begin
      payload, header = JWT.decode(id_token, nil, true, { algorithm: ALGORITHM, verify_iat: true, jwks: jwks})
    rescue JWT::IncorrectAlgorithm
      raise_decode_error('Firebase ID token has incorrect algorithm.')
    rescue JWT::ExpiredSignature
      raise_decode_error('Firebase ID token has expired.')
    rescue JWT::VerificationError
      raise_decode_error('Firebase ID token has invalid signature.')
    rescue StandardError => e
      raise_decode_error("There is a problem with the Firebase ID token: #{e.message}")
    end
    [header, payload]
  end

  def validate(payload)
    validate_aud(payload['aud'])
    validate_iss(payload['iss'])
    validate_sub(payload['sub'])
  end

  def validate_aud(aud)
    return if aud == FIREBASE_PROJECT_ID

    raise_decode_error <<~MSG.squish
      Firebase ID token has incorrect "aud" (audience) claim.
      Expected "#{FIREBASE_PROJECT_ID}" but got "#{aud}".
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
