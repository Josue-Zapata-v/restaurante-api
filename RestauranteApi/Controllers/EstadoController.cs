using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RestauranteApi.Data;

namespace RestauranteApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EstadoController(RestauranteContext context) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> GetEstado(CancellationToken ct)
    {
        // Verifica conexión y tablas, sin revelar servidor, usuario ni contraseña.
        try
        {
            await context.Mesas.AsNoTracking().AnyAsync(ct);
            await context.Reservas.AsNoTracking().AnyAsync(ct);
            return Ok(new { estado = "Disponible", baseDeDatos = "PostgreSQL" });
        }
        catch (Exception) when (!ct.IsCancellationRequested)
        {
            return StatusCode(503, new { estado = "Base de datos no disponible o script pendiente" });
        }
    }
}
