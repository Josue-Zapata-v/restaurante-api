using Microsoft.AspNetCore.Diagnostics;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace RestauranteApi.Infrastructure;

// Traduce conflictos que ocurran entre la comprobación LINQ y SaveChangesAsync.
public sealed class ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception,
        CancellationToken cancellationToken)
    {
        var (status, title) = exception switch
        {
            DbUpdateException { InnerException: SqlException { Number: 2601 or 2627 } } =>
                (409, "Ya existe un registro con ese valor único."),
            DbUpdateException { InnerException: SqlException { Number: 547 } } =>
                (409, "La operación entra en conflicto con registros relacionados."),
            DbUpdateConcurrencyException => (409, "El registro cambió durante la operación. Vuelve a consultarlo."),
            DbUpdateException { InnerException: SqlException { Number: 1205 } } =>
                (409, "Otra operación modificó estos datos. Vuelve a intentarlo."),
            SqlException { Number: 1205 } => (409, "Otra operación modificó estos datos. Vuelve a intentarlo."),
            _ => (500, "No se pudo completar la operación.")
        };

        logger.LogError(exception, "Error de API. TraceId: {TraceId}", context.TraceIdentifier);
        await Results.Problem(statusCode: status, title: title,
            extensions: new Dictionary<string, object?> { ["traceId"] = context.TraceIdentifier })
            .ExecuteAsync(context);
        return true;
    }
}
