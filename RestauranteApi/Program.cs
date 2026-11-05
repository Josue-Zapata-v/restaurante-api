using Microsoft.EntityFrameworkCore;
using RestauranteApi.Data;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("RestauranteDb");
if (string.IsNullOrWhiteSpace(connectionString))
    throw new InvalidOperationException(
        "Configura ConnectionStrings:RestauranteDb con user-secrets o una variable de entorno.");

var allowedOrigin = builder.Configuration["Cors:AllowedOrigin"];
if (!Uri.TryCreate(allowedOrigin, UriKind.Absolute, out var origin)
    || (origin.Scheme != "http" && origin.Scheme != "https")
    || origin.AbsolutePath != "/" || !string.IsNullOrEmpty(origin.Query)
    || !string.IsNullOrEmpty(origin.Fragment) || !string.IsNullOrEmpty(origin.UserInfo))
    throw new InvalidOperationException("Cors:AllowedOrigin debe ser un origen HTTP(S) concreto, sin ruta.");

builder.Services.AddDbContext<RestauranteContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddControllers();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<RestauranteApi.Infrastructure.ApiExceptionHandler>();
builder.Services.AddCors(options => options.AddPolicy("ClienteRestaurante", policy =>
    policy.WithOrigins(origin.GetLeftPart(UriPartial.Authority)).AllowAnyHeader().AllowAnyMethod()));
builder.Services.AddOpenApi(options => options.AddDocumentTransformer((document, _, _) =>
{
    document.Info.Title = "Restaurante API — Mesas y reservas";
    document.Info.Version = "v1";
    document.Info.Description = "Web API REST de Semana 12. Horarios en hora local de Lima, sin Z ni offset.";
    return Task.CompletedTask;
}));

var app = builder.Build();
app.UseExceptionHandler();

// Render termina HTTPS en su proxy; el contenedor recibe HTTP en el puerto 8080.
if (app.Environment.IsDevelopment()) app.UseHttpsRedirection();

app.UseCors("ClienteRestaurante");
// Ambos deben estar disponibles también en Production para la entrega.
app.MapOpenApi();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/openapi/v1.json", "Restaurante API v1");
    options.DocumentTitle = "Restaurante API | Swagger";
    options.DefaultModelsExpandDepth(-1);
});
app.MapControllers();
app.Run();
