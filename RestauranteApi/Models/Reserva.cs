using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace RestauranteApi.Models;

[Index("FechaHora", Name = "IX_Reservas_FechaHora")]
[Index("MesaId", Name = "IX_Reservas_MesaId")]
public partial class Reserva
{
    [Key]
    [Range(0, int.MaxValue)]
    public int Id { get; set; }

    [Required(ErrorMessage = "El nombre del cliente es obligatorio.")]
    [StringLength(100)]
    public string NombreCliente { get; set; } = null!;

    [Required(ErrorMessage = "El teléfono es obligatorio.")]
    [StringLength(20)]
    public string Telefono { get; set; } = null!;

    [Column(TypeName = "timestamp(0) without time zone")]
    [Required]
    [Range(typeof(DateTime), "2000-01-01", "2100-12-31T23:59:59",
        ParseLimitsInInvariantCulture = true,
        ErrorMessage = "Envía una fecha válida entre los años 2000 y 2100.")]
    public DateTime FechaHora { get; set; }

    [Range(1, 20, ErrorMessage = "La cantidad de personas debe estar entre 1 y 20.")]
    public int CantidadPersonas { get; set; }

    [StringLength(300)]
    public string? Observaciones { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "MesaId debe ser un entero positivo.")]
    public int MesaId { get; set; }

    [ForeignKey("MesaId")]
    [InverseProperty("Reservas")]
    public virtual Mesa? Mesa { get; set; }
}
