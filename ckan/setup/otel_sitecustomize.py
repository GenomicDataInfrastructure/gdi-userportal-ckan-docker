import logging
import os
import sys


def _asbool(value):
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _build_exporter_kwargs(protocol):
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    kwargs = {}

    if endpoint:
        kwargs["endpoint"] = endpoint
        if protocol == "grpc":
            kwargs["insecure"] = endpoint.startswith("http://")

    return kwargs


def _install_otel():
    if _asbool(os.getenv("OTEL_SDK_DISABLED", "false")):
        return

    try:
        from opentelemetry import metrics, trace
        from opentelemetry._logs import set_logger_provider
        from opentelemetry.instrumentation.logging import LoggingInstrumentor
        from opentelemetry.instrumentation.requests import RequestsInstrumentor
        from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
        from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
        from opentelemetry.sdk.metrics import MeterProvider
        from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
        from opentelemetry.sdk.resources import SERVICE_NAME, Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        protocol = os.getenv("OTEL_EXPORTER_OTLP_PROTOCOL", "grpc").lower()
        exporter_kwargs = _build_exporter_kwargs(protocol)

        if protocol == "grpc":
            from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
            from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
            from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        else:
            from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter
            from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
            from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

        service_name = os.getenv("OTEL_SERVICE_NAME", "ckan")
        resource = Resource.create({SERVICE_NAME: service_name})

        trace_provider = TracerProvider(resource=resource)
        trace_provider.add_span_processor(
            BatchSpanProcessor(OTLPSpanExporter(**exporter_kwargs))
        )
        trace.set_tracer_provider(trace_provider)

        meter_provider = MeterProvider(
            resource=resource,
            metric_readers=[PeriodicExportingMetricReader(OTLPMetricExporter(**exporter_kwargs))],
        )
        metrics.set_meter_provider(meter_provider)

        logger_provider = LoggerProvider(resource=resource)
        logger_provider.add_log_record_processor(
            BatchLogRecordProcessor(OTLPLogExporter(**exporter_kwargs))
        )
        set_logger_provider(logger_provider)

        LoggingInstrumentor().instrument(set_logging_format=False)
        RequestsInstrumentor().instrument()

        root_logger = logging.getLogger()
        if not any(isinstance(handler, LoggingHandler) for handler in root_logger.handlers):
            root_logger.addHandler(
                LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
            )
    except Exception as exc:  # pragma: no cover - best-effort startup hook
        sys.stderr.write(f"[otel] Failed to initialize OpenTelemetry bootstrap: {exc}\n")


_install_otel()
