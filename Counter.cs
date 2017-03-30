using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication1
{
    public class Counter
    {
        private Dictionary<int, int?> _values = new Dictionary<int, int?>();

        public int? this[int i]
        {
            get 
            {
                int? res;
                _values.TryGetValue(i, out res);
                return res;
            }

            set
            {
                _values.Add(i, value);
            }
        }
    }
}
