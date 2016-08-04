using System;
using System.Collections.Generic;
using System.Linq;

namespace ConsoleApplication10
{
    public class Route
    {
        public string Departure { get; set; }
        public string Arrival { get; set; }
    }

    public class Program
    {
        static void Main(string[] args)
        {
            Route r1 = new Route() { Departure = "Мельбурн", Arrival = "Кельн" };
            Route r2 = new Route() { Departure = "Москва", Arrival = "Париж" };
            Route r3 = new Route() { Departure = "Кельн", Arrival = "Москва" };

            List<Route> unsortedRoutes = new List<Route>() { r2, r3, r1 };

            List<Route> result = GetSortedRoutes(unsortedRoutes);

            Console.WriteLine("Упорядоченный результат:");
            foreach (Route c in result)
            {
                Console.WriteLine(string.Format("{0} -> {1}", c.Departure, c.Arrival));
            }

            Console.Write("\nНажмите любую клавишу для выхода...");
            Console.ReadKey();
        }
        
        public static List<Route> GetSortedRoutes(List<Route> routes)
        {
            List<Route> result = new List<Route>();
            Dictionary<string, Route> dicRoutes = routes.ToDictionary(d => d.Departure);

            string nextDeparture = dicRoutes.Keys.Except(dicRoutes.Values.Select(s => s.Arrival)).Single();

            foreach (var r in routes)
            {
                Route nextRoute;
                dicRoutes.TryGetValue(nextDeparture, out nextRoute);
                result.Add(nextRoute);

                nextDeparture = nextRoute.Arrival;
            }

            return result;
        }
    }
}
