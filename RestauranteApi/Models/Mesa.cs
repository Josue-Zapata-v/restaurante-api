using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;

namespace RestauranteApi.Models;

[Index("Numero", Name = "UQ_Mesas_Numero", IsUnique = true)]
public partial class Mesa
{
    [Key]
    [Range(0, int.MaxValue)]
    public int Id { get; set; }

    [Range(1, 200, ErrorMessage = "El número de mesa debe estar entre 1 y 200.")]
    public int Numero { get; set; }

    [Range(1, 20, ErrorMessage = "La capacidad debe estar entre 1 y 20 personas.")]
    public int Capacidad { get; set; }

    [Required(ErrorMessage = "La ubicación es obligatoria.")]
    [StringLength(80)]
    public string Ubicacion { get; set; } = null!;

    [InverseProperty("Mesa")]
    [JsonIgnore]
    public virtual ICollection<Reserva> Reservas { get; set; } = new List<Reserva>();
}
