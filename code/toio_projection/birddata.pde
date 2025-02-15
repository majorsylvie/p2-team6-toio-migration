// Class created with reference from DeepSeek

import java.util.ArrayList;
import java.util.List;

public class BirdData {
    public List<int[]> points; // List to store (x, y) coordinate points
    public String imagePath;
    
    public BirdData() {
        points = new ArrayList<>();
        imagePath = "";
    }
    public void addPoint(int x, int y) {
        points.add(new int[]{x, y});
    }
    public int getNumPoints() {
        return points.size();
    }
    public void printPoints() {
        for (int[] point : points) {
            System.out.println("(" + point[0] + ", " + point[1] + ")");
        }
    }
}
