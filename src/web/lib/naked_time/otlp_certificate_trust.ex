defmodule NakedTime.OtlpCertificateTrust do
  @moduledoc """
  Builds the SSL options that the OpenTelemetry OTLP exporter uses to trust
  the certificate of the OTLP endpoint.

  During local development the OTLP endpoint is the Aspire dashboard, which
  uses the self-signed development certificate. Erlang's `:ssl` application
  rejects a self-signed peer certificate with `selfsigned_peer` even when the
  same certificate is in the trusted CA file, so `verify/3` accepts a
  self-signed peer certificate only when it exactly matches one of the
  certificates in that file. All other certificates are verified normally.
  """

  @doc """
  Returns the SSL options that trust the certificates in `cacertfile`.
  """
  @spec ssl_options(Path.t()) :: [:ssl.tls_client_option()]
  def ssl_options(cacertfile) do
    trusted =
      cacertfile
      |> File.read!()
      |> :public_key.pem_decode()
      |> Enum.flat_map(fn
        {:Certificate, der, :not_encrypted} -> [der]
        _ -> []
      end)

    [
      verify: :verify_peer,
      cacertfile: String.to_charlist(cacertfile),
      verify_fun: {&__MODULE__.verify/3, trusted}
    ]
  end

  @doc false
  def verify(certificate, {:bad_cert, :selfsigned_peer} = reason, trusted) do
    der = :public_key.pkix_encode(:OTPCertificate, certificate, :otp)

    if der in trusted do
      {:valid, trusted}
    else
      {:fail, reason}
    end
  end

  def verify(_certificate, {:bad_cert, _} = reason, _trusted), do: {:fail, reason}
  def verify(_certificate, {:extension, _}, trusted), do: {:unknown, trusted}
  def verify(_certificate, :valid, trusted), do: {:valid, trusted}
  def verify(_certificate, :valid_peer, trusted), do: {:valid, trusted}
end
